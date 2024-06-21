"""Iterates over all query directories and tries importing them."""

from pathlib import Path

import pytest
from snowflake.snowpark.exceptions import SnowparkSQLException

import queries
from common.query_proxy import Query


def get_all_queries():
    """'Fixture' to produce all query directories.

    Pytest will use this function to generate per-query tests.
    """
    assert len(queries.__path__) == 1
    yield from filter(
        lambda p: p.name not in ("__pycache__", "queries"),
        Path(queries.__path__[0]).glob("**/"),
    )


@pytest.mark.parametrize(
    "query", get_all_queries(), ids=(q.name for q in get_all_queries())
)
def test_create_query_class(query):
    """Try creating a Query class from a query directory."""
    Query(query.name)


@pytest.mark.online
@pytest.mark.parametrize(
    "query", get_all_queries(), ids=(q.name for q in get_all_queries())
)
def test_create_and_run_all_sprocs(query, snowpark_session):
    """Create and run all stored procedures one by one."""
    query = Query(query.name)

    try:
        snowpark_session.sql(query.as_sql_sproc()).collect()
    except SnowparkSQLException as e:
        print(
            f"Could not create stored procedure '{query.title}'; most likely a syntax error"
        )
        raise e

    try:
        snowpark_session.sql(f"CALL {query.sproc_name}()").collect()
    except SnowparkSQLException as e:
        print(f"Did not successfully call the stored procedure '{query.title}'")
        raise e
