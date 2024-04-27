"""Tests the Query class."""
from operator import attrgetter
from textwrap import dedent

import pytest

from common.query_proxy import Query

# NOTE: slightly leaks app implementation. Better approach - stub out all queries in a fixture
STUB_QUERY = Query(source_name="num_failures")


def test_query_text():
    """Checks that the query text is a string."""
    assert isinstance(STUB_QUERY.query_text, str)


def test_description():
    """Checks that the query description is a string."""
    assert isinstance(STUB_QUERY.description, str)


def test_blurb():
    """Checks that the query blurb is a string."""
    assert isinstance(STUB_QUERY.blurb, str)


def test_sproc_return_types():
    """Checks that sproc return types are parsed properly."""
    return_types = STUB_QUERY.sproc_return_types
    assert return_types == (
        ("USER_NAME", "String"),
        ("ERROR_MESSAGE", "String"),
        ("NUM_OF_FAILURES", "Integer"),
    )


def test_sql_sproc():
    """Checks the stored procedure is correct."""
    assert STUB_QUERY.as_sql_sproc() == dedent(
        """\
                  CREATE OR REPLACE PROCEDURE SENTRY_num_failures ()
                  RETURNS TABLE(USER_NAME String, ERROR_MESSAGE String, NUM_OF_FAILURES Integer)
                  LANGUAGE SQL
                  AS
                  $$
                  DECLARE
                  res RESULTSET;
                  BEGIN
                  res :=(select
                      user_name,
                      error_message,
                      count(*) num_of_failures
                  from
                      SNOWFLAKE.ACCOUNT_USAGE.login_history
                  where
                      is_success = 'NO'
                  group by
                      user_name,
                      error_message
                  order by
                      num_of_failures desc
                  );
                  RETURN TABLE(res);
                  END
                  $$"""
    )


def test_sproc_name():
    """Checks that the query stored procedure name is a string."""
    assert isinstance(STUB_QUERY.sproc_name, str)


@pytest.mark.parametrize(
    "field,metadata_type",
    [
        ("title", str),
        ("tile_identifier", str),
        ("dashboard", str),
        ("security_features_checklist", tuple),
        ("nist_800_53", tuple),
        ("nist_800_171", tuple),
        ("hitrust_csf_v9", tuple),
        ("mitre_attack_saas", tuple),
    ],
)
def test_metadata_types(field, metadata_type):
    """A generic test that checks the expected types of metadata.

    For tuples the value is also checked against fallbacks.
    """
    test_subject = attrgetter(field)(STUB_QUERY)
    if metadata_type is tuple:
        assert any(
            [
                isinstance(test_subject, metadata_type),
                isinstance(test_subject, str),
                (test_subject is None),
            ]
        )
    else:
        assert isinstance(test_subject, metadata_type)
