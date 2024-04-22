"""Python project management scripts."""
from pathlib import Path

from toolz import pipe
from toolz.curried import filter

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
    """Produce a sorted list of all queries."""
    return pipe(
        Path(queries.__path__[0]).glob("**/"),
        sorted,
        filter(
            lambda p: p.name not in ("__pycache__", "queries"),
        ),
    )


def render_stored_procedures():
    """Render the documentation for stored procedures."""
    for query_dir in _iterate_over_queries():
        query = Query(query_dir.name)
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
        query = Query(query_dir.name)
        print(query.as_sql_sproc() + ";")
