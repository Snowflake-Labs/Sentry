"""Contains implementation and definitions of Tiles -- the main helper object of this app.

Tiles are self-contained objects that combine the query to fetch the data with the method of rendering a tile on the
page.
"""

from functools import partial
from typing import Any, Callable, Generator, NamedTuple

import altair as alt
import streamlit as st
from snowflake.snowpark.context import get_active_session

import common.queries as queries
from common.queries import (
    ACCOUNTADMIN_GRANTS,
    ACCOUNTADMIN_NO_MFA,
    AUTH_BY_METHOD,
    AUTH_BYPASSING,
    AVG_NUMBER_OF_ROLE_GRANTS_PER_USER,
    DEFAULT_ROLE_CHECK,
    GRANTS_TO_PUBLIC,
    GRANTS_TO_UNMANAGED_SCHEMAS_OUTSIDE_SCHEMA_OWNER,
    LEAST_USED_ROLE_GRANTS,
    MOST_BLOATED_ROLES,
    MOST_DANGEROUS_PERSON,
    NETWORK_POLICY_CHANGES,
    NUM_FAILURES,
    PRIVILEGED_OBJECT_CHANGES_BY_USER,
    SCIM_TOKEN_LIFECYCLE,
    SHARING_LISTING_ALTER,
    SHARING_LISTING_USAGE,
    SHARING_READER_CREATION_MONITOR,
    SHARING_REPLICATION_HISTORY,
    SHARING_SHARE_ALTER,
    STALE_USERS,
    USER_ROLE_RATIO,
    USERS_BY_OLDEST_PASSWORDS,
)
from common.query_proxy import Query


class Tile(NamedTuple):
    """Composable object to retrieve data from Snowflake and render it on a page."""

    query: Query
    name: str = ""
    # NOTE: this might not work if pushed into a Streamlit container
    render_f: Callable = partial(st.dataframe, use_container_width=True)

    def render(self):
        """Produce a Tile's representation on the page."""
        st.subheader(self.name or self.query.title)
        session = get_active_session()
        with st.spinner("Fetching data..."):
            data = session.sql(self.query.query_text).to_pandas()
        self.render_f(data)

        with st.expander(label="More details"):
            st.markdown(self.query.blurb)

            st.markdown("**Query:**")

            st.code(self.query.query_text)


def render(tile: Tile) -> Any:
    """Call Tile.render in a functional way."""
    return tile.render()


def _mk_tiles(*tiles) -> Generator[Tile, Any, None]:
    """Generate Tile instances by unpacking the provided iterable."""
    return (Tile(**i) if isinstance(i, dict) else Tile(query=i) for i in tiles)


altair_chart = partial(
    st.altair_chart, use_container_width=True
)  # NOTE: theme="streamlit" is default

AuthTiles = _mk_tiles(
    {
        "query": NUM_FAILURES,
        "render_f": lambda data: altair_chart(
            alt.Chart(data)
            .mark_bar()
            .encode(
                x=alt.X("USER_NAME", type="nominal", sort="-y", title="User"),
                y=alt.Y("NUM_OF_FAILURES", aggregate="sum", title="Login failures"),
                color="ERROR_MESSAGE",
            ),
        ),
    },
    {
        "query": AUTH_BY_METHOD,
        "render_f": lambda data: altair_chart(
            alt.Chart(data)
            .mark_bar()
            .encode(
                x=alt.X("COUNT(*)", type="quantitative", title="Event Count"),
                y=alt.Y(
                    "AUTHENTICATION_METHOD", type="nominal", title="Method", sort="-x"
                ),
            ),
        ),
    },
    AUTH_BYPASSING,
)

PrivilegedAccessTiles = _mk_tiles(
    ACCOUNTADMIN_GRANTS,
    ACCOUNTADMIN_NO_MFA,
    DEFAULT_ROLE_CHECK,
)

IdentityManagementTiles = _mk_tiles(
    USERS_BY_OLDEST_PASSWORDS,
    STALE_USERS,
    SCIM_TOKEN_LIFECYCLE,
)

LeastPrivilegedAccessTiles = _mk_tiles(
    {
        "query": MOST_DANGEROUS_PERSON,
        "render_f": lambda data: altair_chart(
            alt.Chart(data)
            .mark_bar()
            .encode(
                x=alt.X(
                    "NUM_OF_PRIVS", type="quantitative", title="Number of privileges"
                ),
                y=alt.Y("USER", type="nominal", title="User", sort="-x"),
            ),
        ),
    },
    MOST_BLOATED_ROLES,
    GRANTS_TO_PUBLIC,
    GRANTS_TO_UNMANAGED_SCHEMAS_OUTSIDE_SCHEMA_OWNER,
    USER_ROLE_RATIO,
    AVG_NUMBER_OF_ROLE_GRANTS_PER_USER,
    LEAST_USED_ROLE_GRANTS,
)

ConfigurationManagementTiles = _mk_tiles(
    {
        "query": PRIVILEGED_OBJECT_CHANGES_BY_USER,
        "render_f": lambda data: altair_chart(
            alt.Chart(data)
            .mark_bar()
            .encode(
                x=alt.X("USER_NAME", type="nominal", sort="-y", title="User"),
                y=alt.Y("QUERY_TEXT", aggregate="count", title="Number of Changes"),
            )
        ),
    },
    NETWORK_POLICY_CHANGES,
)

SharingTiles = _mk_tiles(
    SHARING_READER_CREATION_MONITOR,
    SHARING_SHARE_ALTER,
    SHARING_LISTING_ALTER,
    SHARING_LISTING_USAGE,
    SHARING_REPLICATION_HISTORY,
    queries.SHARING_AGGREGATE_ACCESS_OVER_TIME_BY_CONSUMER,
    queries.SHARING_ACCESS_COUNT_BY_COLUMN,
    queries.SHARING_TABLE_JOINS_BY_CONSUMER,
)

May30TTPsGuidanceTiles = _mk_tiles(
    queries.IP_LOGINS,
    queries.FACTOR_BREAKDOWN,
    queries.IPS_WITH_FACTOR,
    queries.STATIC_CREDS,
    queries.QUERY_HISTORY,
    queries.AUTH_BY_METHOD,
    queries.ACCOUNTADMIN_GRANTS,
    queries.ACCOUNTADMIN_NO_MFA,
    queries.NETWORK_POLICY_CHANGES,
    queries.ANOMALOUS_APPLICATION_ACCESS,
)
