"""This is a small rewrite of the original app that is focused on getting all code into a single file."""

import itertools
import re
from dataclasses import asdict, dataclass
from operator import itemgetter, methodcaller
from typing import Callable, List, Optional

import pandas as pd
import streamlit as st
from snowflake.snowpark.context import get_active_session
from streamlit.navigation.page import StreamlitPage
from toolz import pipe
from toolz.curried import do as cdo
from toolz.curried import filter as cfilter
from toolz.curried import map as cmap
from toolz.curried import pluck as cpluck

st.set_page_config(layout="wide")
# Connection short-circuits in SiS, creating the session immediately
session = st.connection("securitylab2", type="snowflake").session()


def user_management():
    """Page to manage users' passwords.

    The goal is to minimize the amount of users using only passwords used and transition to one of:

        - Combination of password + MFA
        - SSO
        - SAML
        - Keypair authentication

    The application returns all users that have logged in at least once.

    Bugs:
        - Changing multiselect resets the selection
    """
    query = """
    WITH last_authentication_method AS (
    SELECT
        user_name,
        first_authentication_factor AS auth_method,
        count(*) AS num_of_times,
        max(event_timestamp) AS last_time_used

    FROM snowflake.account_usage.login_history
    WHERE client_ip != '0.0.0.0'
    AND is_success = 'YES'
    GROUP BY 1, 2 ORDER BY 1, 2
    )
    SELECT
        name,
        type,
        default_role,
        disabled,
        has_password,
        password_last_set_time,
        has_rsa_public_key,
        has_mfa,
        snowflake_lock,
        saml.num_of_times saml_num_of_times,
        saml.last_time_used saml_last_time_used,
        keypair.num_of_times keypair_num_of_times,
        keypair.last_time_used keypair_last_time_used,
        oauth.num_of_times oauth_num_of_times,
        oauth.last_time_used oauth_last_time_used
    FROM
        snowflake.account_usage.users u
        LEFT JOIN last_authentication_method saml
            ON
                u.name = saml.user_name
                AND saml.auth_method = 'SAML2_ASSERTION'
        LEFT JOIN last_authentication_method keypair
            ON
                u.name = keypair.user_name
                AND keypair.auth_method = 'RSA_KEYPAIR'
        LEFT JOIN last_authentication_method oauth
            ON
                u.name = oauth.user_name
                AND oauth.auth_method = 'OAUTH_ACCESS_TOKEN'
    WHERE
        1 = 1
        NEEDLE
    ORDER BY has_password = true DESC, password_last_set_time;
    """

    @dataclass
    class PreFilter:
        """PreFilter allows mutating the data retrieval query to filter data before it's presented.

        They shall act as extra filters appended to WHERE in the main data producing query
        """

        human_name: str
        rule: str  # Gets appended to the WHERE clause
        enabled: bool = False

        def should_be_enabled(self):
            """Render the checkbox and set the enabled property of the object."""
            self.enabled = st.checkbox(self.human_name)

    # `cache_data` allows caching the data on the streamlit process side
    # it also allows operating on the rows that were selected in the table
    @st.cache_data
    def get_data(filters: Optional[List[PreFilter]] = None):
        """Produce the data from SNOWFLAKE database."""
        final_query = query
        if filters is None or len(filters) == 0:
            final_query = re.sub("NEEDLE", "", query)
        else:
            # Singleton it
            if not isinstance(filters, list):
                applied_filters = [filters]
            else:
                applied_filters = filters

            applied_filters = pipe(
                applied_filters,
                cmap(asdict),
                cpluck("rule"),
                cmap(lambda it: f"AND {it}"),
                "\n ".join,
            )

            final_query = re.sub("NEEDLE", applied_filters, query)
        return session.sql(final_query).to_pandas()

    @dataclass
    class Action:
        """Represents one of the actions to be done."""

        mk_query: Callable
        btn_label: str

    def _mk_user_type_action(future_user_type):
        return Action(
            mk_query=lambda it: f"ALTER USER IDENTIFIER('\"{it}\"') SET TYPE = {future_user_type}",
            btn_label=f"Set '{future_user_type}' user type",
        )

    filters = [
        PreFilter("User has password set", "has_password=true"),
        PreFilter("User has MFA set", "has_mfa=true"),
    ]

    password = Action(
        mk_query=lambda it: f"ALTER USER IDENTIFIER('\"{it}\"') UNSET PASSWORD",
        btn_label="Unset password",
    )
    to_person_type = _mk_user_type_action("PERSON")
    to_service_type = _mk_user_type_action("SERVICE")
    to_legacy_service_type = _mk_user_type_action("LEGACY_SERVICE")

    actions = (password, to_person_type, to_service_type, to_legacy_service_type)

    # UI starts here

    # Render pre-filters, collect checkbox status
    st.header("Filters")
    filters = pipe(
        filters,
        cmap(cdo(PreFilter.should_be_enabled)),
        cfilter(lambda it: it.enabled),
        list,
    )
    data = get_data(filters)

    show_columns = pipe(
        data,
        list,
        lambda it: st.multiselect(
            "Select",
            options=it,
            default=pipe(
                [
                    "name",
                    "type",
                    "default_role",
                    "has_password",
                    "has_mfa",
                    "snowflake_lock",
                    "saml_last_time_used",
                    "keypair_last_time_used",
                    "oauth_last_time_used",
                ],
                cmap(str.upper),
            ),
            label_visibility="hidden",
        ),
    )

    # Render the dataframe, catching selection events in `event`
    event = st.dataframe(
        data[show_columns],
        use_container_width=True,
        hide_index=True,
        on_select="rerun",
        selection_mode="multi-row",
    )

    st.header("Selected users")
    people = event.selection.rows
    st.write(data.iloc[people][show_columns])

    selected_users = data.iloc[people]["NAME"].tolist()

    # Render the UI for the actions
    st.header("Actions")
    for col, action in zip(st.columns(len(actions)), actions):
        if col.button(action.btn_label):
            if len(selected_users) >= 1:
                changes = pipe(
                    selected_users,  # Take users
                    cmap(action.mk_query),  # Create queries
                    cmap(cdo(lambda it: session.sql(it).collect())),
                    list,
                )
                st.info("All done")
                with st.expander("Queries ran"):
                    pipe(changes, "\n".join, st.code)

            else:
                st.info("Please select at least one user")


def network_rules():
    """Page with UI to create network rules."""
    query = """
    SELECT
        client_ip,
        count(distinct user_name) user_count,
        listagg(distinct user_name, ', ') within group (order by user_name) as users
    FROM snowflake.account_usage.login_history
    WHERE client_ip <> '0.0.0.0'
    GROUP BY 1
    ORDER BY user_count DESC;
    """

    @st.cache_data
    def get_data():
        return session.sql(query).to_pandas()

    data = get_data()
    st.write("Select an IP address from this list to generate the network rule")
    search_by_user = st.multiselect(
        label="Search by user",
        options=pipe(
            data["USERS"].tolist(),
            cmap(lambda it: it.split(", ")),
            lambda it: itertools.chain(*it),
            set,
        ),
    )

    def _filter_by_users(row) -> bool:
        # If search_by_user is not set, return all rows
        if search_by_user == []:
            return True
        # Else, filter the row value by checking if the set contains one of the selected users
        return pipe(
            row["USERS"],
            lambda it: it.split(", "),
            set,
            lambda it: it.intersection(set(search_by_user)),
            len,
            bool,
        )

    event = st.dataframe(
        data[data.apply(_filter_by_users, axis=1)],
        use_container_width=True,
        hide_index=True,
        on_select="rerun",
        selection_mode="multi-row",
    )

    selected_ips = pipe(
        event.selection.rows,
        (lambda it: get_data().iloc[it]),
        (itemgetter("CLIENT_IP")),
        (methodcaller("to_list")),
    )

    if len(selected_ips) > 0:
        c1, c2, c3 = st.columns(3)
        policy_name = c1.text_input("Name the network policy")
        # Network policy is a schema object
        target_db = c2.selectbox(
            label="Database",
            options=pipe(
                "SHOW TERSE DATABASES",
                lambda it: session.sql(it).collect(),
                cpluck("name"),
            ),
        )
        target_schema = c3.selectbox(
            label="Schema",
            options=pipe(
                f"SHOW TERSE SCHEMAS IN DATABASE IDENTIFIER('{target_db}')",
                lambda it: session.sql(it).collect(),
                cpluck("name"),
                cfilter(
                    lambda it: it.lower() != "information_schema"
                ),  # INFORMATION_SCHEMA is read-only
            ),
        )

        if policy_name != "":
            # TODO: use rest API here when actually implementing the "GO" button
            sql = f"""
            CREATE NETWORK RULE IDENTIFIER(\"'{target_db}.{target_schema}.network_rule_{policy_name}'\")
                TYPE = IPV4
                VALUE_LIST = ({pipe(selected_ips, cmap(lambda it: f"'{it}'"), ", ".join)})
                MODE = INGRESS
                COMMENT = 'Generated by SAFE'
            """
            st.code(sql, language="sql")
            if st.button("Create"):
                pipe(sql, session.sql, st.dataframe)


pipe(
    # Add pages here
    [
        (user_management, "User management", "person"),
        (network_rules, "Network rules", "vpn_lock"),
    ],
    # Transform tuples into format compatible with st.Page signature
    cmap(lambda it: {"page": it[0], "title": it[1], "icon": f":material/{it[2]}:"}),
    # Call st.Page
    cmap(lambda it: st.Page(**it)),
    # Turn into a list from a map
    list,
    # Call st.navigation which will produce a chosen page
    st.navigation,
    # Run the page
    StreamlitPage.run,
)
