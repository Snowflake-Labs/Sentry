"""Bag of utility functions."""

import streamlit as st
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session
from snowflake.snowpark.exceptions import SnowparkSessionException


def maybe_connect() -> Session:
    """Produce a Session object to connect to Snowflake.

    Depending on the runtime (locally vs Streamlit-in-Snowflake), creates a new connection.
    """
    try:
        return get_active_session()
    except SnowparkSessionException:
        return st.experimental_connection("default", type="snowpark").session


# TODO: SiS-aware cache_data decorator


def sidebar_footer() -> None:
    """Show a footer on sidebar with links to code and docs."""
    with st.sidebar:
        st.subheader("About the app")
        st.markdown("[Documentation](https://snowflake-labs.github.io/Sentry/)")
        st.markdown("[Source code](https://github.com/Snowflake-Labs/Sentry)")
