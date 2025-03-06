"""Bag of utility functions."""

import streamlit as st
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session
from snowflake.snowpark.exceptions import SnowparkSessionException

# TODO: SiS-aware cache_data decorator


def sidebar_footer() -> None:
    """Show a footer on sidebar with links to code and docs."""
    with st.sidebar:
        st.subheader("About the app")
        st.markdown("[Documentation](https://snowflake-labs.github.io/Sentry/)")
        st.markdown("[Source code](https://github.com/Snowflake-Labs/Sentry)")
