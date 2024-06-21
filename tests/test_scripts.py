"""Tests for various project scripts."""

from functools import cmp_to_key
from random import shuffle

import pytest

from scripts.scripts import table_sort_compare


@pytest.mark.parametrize(
    "left,right,result",
    [
        ("AUTH-10", "AUTH-1", 1),
        ("AUTH-10", "USER-1", -1),
        ("AUTH-1", "AUTH-1", 0),
        ("AUTH-1", "USER-1", -1),
    ],
)
def test_table_sort_lt(left, right, result):
    """Test individual comparisons."""
    assert table_sort_compare(left, right) == result


def test_table_sort_specific_order():
    """'Integration' test for the function. It's expected to be used as a comparison in sorted.

    The tested list is representative of real list of metadata values.
    """
    test_subject = ["AUTH-1", "SECRETS-13", "SECRETS-3", "USER-1", "SECRETS-8"]
    shuffle(test_subject)

    assert sorted(test_subject, key=cmp_to_key(table_sort_compare)) == [
        "AUTH-1",
        "SECRETS-3",
        "SECRETS-8",
        "SECRETS-13",
        "USER-1",
    ]
