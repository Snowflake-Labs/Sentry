"""Main entrypoint. Contains tiles reporting on Authentication."""

import streamlit as st
import toolz as t
import toolz.curried as tc
from snowflake.snowpark.context import get_active_session
from toolz import pipe
from toolz.curried import map as cmap

from common.tiles import (
    AuthTiles,
    ConfigurationManagementTiles,
    IdentityManagementTiles,
    LeastPrivilegedAccessTiles,
    May30TTPsGuidanceTiles,
    PrivilegedAccessTiles,
    SharingTiles,
    render,
)
from common.utils import sidebar_footer


def _mk_connection():
    """Wrap around get_active_session to gracefully handle multiple windows open."""
    try:
        get_active_session()
    except Exception as e:
        # no default session is not a typed exception, need to parse the message
        if "No default Session is found" in e.message:
            st.connection("default", type="snowflake").session()
        else:
            raise


def _mk_page(tiles):
    """Return the function that will actually render the page."""

    def _inner():
        pipe(tiles, cmap(render), list)

    return _inner


pipe(
    (
        (AuthTiles, "Authentication"),
        (ConfigurationManagementTiles, "Configuration Management"),
        (SharingTiles, "Data Sharing"),
        (IdentityManagementTiles, "Identity Management"),
        (LeastPrivilegedAccessTiles, "Least Privileged Access"),
        (May30TTPsGuidanceTiles, "May 30 TTPs Guidance"),
        (PrivilegedAccessTiles, "Privileged Access"),
    ),
    # Wrap in st.Page call
    # `url_path` is necessary otherwise streamlit will error out when trying to construct URLs
    cmap(lambda it: st.Page(_mk_page(it[0]), title=it[1], url_path=it[1])),
    # Materialize
    list,
    # Assemble navigation
    st.navigation,
    # Force render footer
    tc.do(lambda _: sidebar_footer()),
    # Connection is created here so that the sidebar is fully rendered by this point
    tc.do(lambda _: _mk_connection()),
    # Finally run the current page. If ordered earlier, the sidebar pages will not be rendered
    lambda it: it.run(),
)
