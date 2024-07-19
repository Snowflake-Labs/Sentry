"""Main entrypoint. Contains tiles reporting on Authentication."""

from toolz import pipe
from toolz.curried import map
import functools
import streamlit as st

from common.tiles import AuthTiles, render
from common.utils import maybe_connect, sidebar_footer

# Before the tiles so it renders first
sidebar_footer()

# NOTE: since this is the main entry point, call to maybe_session ensures that the Snowpark Session is properly
# generated
session = maybe_connect()

render = functools.partial(render, query_db=st.session_state.get("QUERY_DB", "SNOWFLAKE"))

pipe(AuthTiles, map(render), list)
