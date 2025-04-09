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
    GROUP BY 1, 2
    ),
    user_network_policy as (
    select user_name,
    'CREATE NETWORK POLICY ' || translate(user_name, '@+.', '___') || '_POLICY ALLOWED_IP_LIST=(''' ||
    listagg(distinct client_ip, ''',''') within group (order by client_ip) || ''');' as run_these
    from snowflake.account_usage.login_history
    where client_ip != '0.0.0.0' and is_success = 'YES'
    group by user_name
    )
    SELECT
        name,
        login_name,
        email,
        type,
        default_role,
        disabled,
        has_password,
        password_last_set_time,
        last_success_login,
        has_rsa_public_key,
        has_mfa,
        snowflake_lock,
        owner,
        saml.num_of_times saml_num_of_times,
        saml.last_time_used saml_last_time_used,
        keypair.num_of_times keypair_num_of_times,
        keypair.last_time_used keypair_last_time_used,
        oauth.num_of_times oauth_num_of_times,
        oauth.last_time_used oauth_last_time_used,
        password.num_of_times password_num_of_times,
        password.last_time_used password_last_time_used,
        nvl(nvl(unetpol.policy_name, anetpol.policy_name), run_these) as policy_name_or_possible_policy,
        run_these as possible_policy
    FROM
        snowflake.account_usage.users u
        LEFT JOIN last_authentication_method saml
            ON u.name = saml.user_name
                AND saml.auth_method = 'SAML2_ASSERTION'
        LEFT JOIN last_authentication_method keypair
            ON u.name = keypair.user_name
                AND keypair.auth_method = 'RSA_KEYPAIR'
        LEFT JOIN last_authentication_method oauth
            ON u.name = oauth.user_name 
                AND oauth.auth_method = 'OAUTH_ACCESS_TOKEN
    '
        LEFT JOIN last_authentication_method password
            ON u.name = password.user_name
                AND password.auth_method = 'PASSWORD'

        LEFT JOIN snowflake.account_usage.policy_references unetpol
            ON NAME = unetpol.ref_entity_name AND unetpol.policy_kind = 'NETWORK_POLICY'
                AND unetpol.ref_entity_domain = 'USER'
        LEFT JOIN snowflake.account_usage.policy_references anetpol
            ON anetpol.policy_kind = 'NETWORK_POLICY'
                AND anetpol.ref_entity_domain = 'ACCOUNT'
        LEFT JOIN user_network_policy pol ON u.name = pol.user_name
        WHERE
            1 = 1
            and u.deleted_on is null and (u.type != 'SNOWFLAKE_SERVICE' or u.type is null)
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
        help: Optional[str] = None

        def should_be_enabled(self):
            """Render the checkbox and set the enabled property of the object."""
            self.enabled = st.checkbox(self.human_name, help=self.help)

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
        return session.sql(final_query).to_pandas(), final_query

    @dataclass
    class Action:
        """Represents one of the actions to be done."""

        mk_query: Callable
        btn_label: str

        def apply_to_users(self, users) -> list[str]:
            return pipe(
                users,  # Take users
                cmap(self.mk_query),  # Create queries
                cmap(cdo(lambda it: session.sql(it).collect())),
                list,
            )

    def _mk_user_type_action(future_user_type):
        return Action(
            mk_query=lambda it: f"ALTER USER IDENTIFIER('\"{it}\"') SET TYPE = {future_user_type}",
            btn_label=f"Set '{future_user_type}' user type",
        )

    filters = [
        PreFilter("User has password set", "has_password=true"),
        PreFilter("User has not enrolled in MFA", "has_mfa=false"),
        PreFilter("User has used SSO", "saml_last_time_used is not null"),
        PreFilter(
            "User appears to have an email address",
            "u.login_name ilike '%@%.%'",
            help="Often email-like usernames indicate human users",
        ),
        PreFilter(
            "User type is null",
            "type is null",
            help="""Users should be one of the types described in
                  [this doc](https://docs.snowflake.com/en/user-guide/admin-user-management#label-user-management-types).""",
        ),
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
    st.info(
        """This application is a best effort tool for use by Snowflake Customers. Its generated output should be
                carefully reviewed and tested prior to any use within a Snowflake account"""
    )
    st.write(
        """Please use the checkboxes to filter and use the grid to sort; find users you can choose to remove passwords
            for or assign User Types to."""
    )
    filters = pipe(
        filters,
        cmap(cdo(PreFilter.should_be_enabled)),
        cfilter(lambda it: it.enabled),
        list,
    )
    data, query = get_data(filters)

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
                    "password_last_time_used",
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

    st.write("Click rows, or select-all to populate the grid below and...")
    people = event.selection.rows
    st.write(data.iloc[people][show_columns])

    selected_users = data.iloc[people]["NAME"].tolist()

    # Render the UI for the actions
    @st.dialog("Confirm changes")
    def confirm_password_changes(users: list[str]) -> None:
        st.write(f"Confirm password removal for the following {len(users)} users:")
        st.write(users)

        st.session_state["confirmed_password_change"] = False
        # st.rerun will close the modal
        if st.button("Confirm"):
            st.session_state["confirmed_password_change"] = True
            st.rerun()

        if st.button("Discard"):
            st.rerun()

    if "confirmed_password_change" not in st.session_state:
        st.session_state["confirmed_password_change"] = None

    st.write("...click a button to take action on those users.")
    for col, action in zip(st.columns(len(actions)), actions):
        if col.button(action.btn_label):
            if len(selected_users) >= 1:
                # Ask the user to confirm removing password from users
                if action is password:
                    confirm_password_changes(selected_users)

                if action is not password:
                    changes = action.apply_to_users(selected_users)
                    st.info("All done")
                    with st.expander("Queries ran"):
                        pipe(changes, "\n".join, st.code)

            else:
                st.info("Please select at least one user")

        if st.session_state["confirmed_password_change"]:
            changes = action.apply_to_users(selected_users)
            st.info("All done")
            with st.expander("Queries ran"):
                pipe(changes, "\n".join, st.code)

            st.session_state["confirmed_password_change"] = False

    st.info(
        """Note: results from your actions won't appear above for a few hours because of the standard
            [`ACCOUNT_USAGE` latency](https://docs.snowflake.com/en/sql-reference/account-usage#data-latency)"""
    )

    with st.expander("User retrieval query (for reference)"):
        st.code(query, language="sql")


pipe(
    # Add pages here
    [
        (user_management, "User management", "person"),
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
