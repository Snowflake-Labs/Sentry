"""Python project management scripts."""
import math
from functools import cmp_to_key, partial
from operator import attrgetter
from pathlib import Path

from pandas import DataFrame
from toolz import pipe
from toolz.curried import filter
from toolz.curried import map as cmap

import queries
from common.query_proxy import Query


def _md_break_line(line: str, textwidth: int = 80) -> str:
    """(semi) word-aware line break insert after no more than specified amount of characters.

    This function will be mostly used to split text components so that markdown lines stay under limit specified in
    markdownlint.
    """
    if all([len(fragment) < textwidth for fragment in line.split("\n")]):
        return line
    else:
        point = textwidth - 1
        sigil_at_point = line[point]
        if sigil_at_point == " ":
            return _md_break_line(line[:point] + "\n" + line[point:])
        else:
            before_point = line[:point]
            return _md_break_line("\n".join(before_point.rsplit(" ", 1)) + line[point:])


def _iterate_over_queries():
    """Produce a sorted list of all queries.

    Does not cast the value as a Query object since downstream consumer might want to tweak it.
    """
    return pipe(
        Path(queries.__path__[0]).glob("**/"),
        sorted,
        filter(
            lambda p: p.name not in ("__pycache__", "queries"),
        ),
        cmap(attrgetter("name")),
    )


def render_stored_procedures():
    """Render the documentation for stored procedures."""
    for query_dir in _iterate_over_queries():
        query = Query(query_dir)
        query_blurb = query.blurb + "\n" if query.blurb else ""

        output = [
            f"# {query.title}\n",
            _md_break_line(query_blurb),
            # query_blurb,
            "```sql",
            query.as_sql_sproc(),
            "```\n",
        ]

        pipe(output, filter(None), "\n".join, print)


def render_sprocs_as_single_file():
    """Render the documentation for sprocs as single file.

    Used for a single EXECUTE IMMEDIATE FROM $file.
    """
    for query_dir in _iterate_over_queries():
        query = Query(query_dir)
        print(query.as_sql_sproc() + ";")


def table_sort_compare(left: str, right: str) -> int:
    """Compare by the custom identifier order.

    The string part is compared through dictionary, the numeric part through natural order.

    Effective:

    AUTH-10, USER-1 -> -1
    AUTH-1, AUTH-1 -> 0
    AUTH-10, AUTH-1 -> 1

    """
    sort_order = {"AUTH": 0, "CONFIG": 1, "SECRETS": 2, "USER": 3, "ROLES": 4}
    l, r = pipe(
        [left, right],  # [ AUTH-1, AUTH-10 ]
        cmap(lambda s: str.split(s, "-")),  # [[AUTH, "1"], [AUTH, "10"]
        cmap(lambda x: [x[0], int(x[1])]),  # [[AUTH, 1], [AUTH, 10]]
        tuple,  # Materialize, otherwise map object will be consumed
        # lambda li: sort_order[li[0][0]] < sort_order[li[1][0]] or li[0][1] < li[1][1]
    )
    if l == r:
        return 0
    if l[0] != r[0]:
        result = sort_order[l[0]] - sort_order[r[0]]
    else:
        result = l[1] - r[1]

    return int(math.copysign(1, result))


def render_queries_as_a_table() -> None:
    """Print single table that maps queries to specific controls."""

    def _columns_printable(val):
        if isinstance(val, tuple):
            return ", ".join(map(str, val))
        return val

    pipe(
        _iterate_over_queries(),
        # TODO: Once the metadata is filled in, remove the filter
        filter(
            lambda x: x
            not in {
                "auth_by_method",
                "accountadmin_no_mfa",
                "scim_token_lifecycle",
            }
        ),
        # Create Query instances
        cmap(Query),
        # Apply order by the tile_identifier prop
        partial(
            sorted,
            key=cmp_to_key(
                lambda left, right: table_sort_compare(
                    left.tile_identifier, right.tile_identifier
                )
            ),
        ),
        # Extract only metadata attribute
        cmap(attrgetter("metadata")),
        # TODO: Human-readable column names, not technical ones
        # Maybe just serialize and load the json?
        # Turn it into a dict
        cmap(dict),
        # Load into a dataframe
        partial(DataFrame.from_records),
        # Apply formatting
        partial(DataFrame.applymap, func=_columns_printable),
        # Drop unneeded columns
        partial(DataFrame.drop, columns=["blurb"]),
        # Print
        partial(DataFrame.to_markdown, index=False),
        print,
    )
