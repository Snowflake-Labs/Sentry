"""Main entrypoint. Contains tiles reporting on Authentication."""

import streamlit as st
from toolz import pipe
from toolz.curried import map

from common.tiles import AuthTiles, render
from common.utils import sidebar_footer

# Before the tiles so it renders first
sidebar_footer()

# Initiate the connection to ensure that get_active_session() calls will succeed
st.connection("default", type="snowflake")

pipe(AuthTiles, map(render), list)
