"""Base pytest fixtures and settings."""

from pathlib import Path

import pytest
from snowflake.snowpark import Session
from tomlkit import load


@pytest.fixture
def snowpark_session() -> Session:
    """Reuse streamlit secrets to create a Snowpark session."""
    with open(Path(__file__).parent.parent / ".streamlit" / "secrets.toml", "rb") as f:
        return Session.builder.configs(load(f)["connections"]["default"]).create()


def pytest_addoption(parser):
    """Add options to the pytest parser."""
    parser.addoption(
        "--online",
        action="store_true",
        dest="online",
        default=False,
        help="enable online tests",
    )


def pytest_configure(config):
    """Apply default config to pytest."""
    if not config.option.online:
        setattr(config.option, "markexpr", "not online")
