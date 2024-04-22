"""Interfaces between files and tiles/stored procedures."""
import dataclasses
from pkgutil import get_data
from typing import ClassVar, Tuple

from vendored.python_frontmatter import frontmatter


@dataclasses.dataclass
class Query:
    """Proxy for the .sql and the document file."""

    source_name: str
    _query_text: str = None
    _description: str = None
    _title: str = None
    _blurb: str = None
    # NOTE: before 3.9 it cannot be a builtin tuple(), need typing.Tuple
    _sproc_return_types: Tuple[str, str] = dataclasses.field(default_factory=tuple)
    _package_name: ClassVar[str] = "queries"
    _app_name: ClassVar[str] = "SENTRY"

    def _read_text(self, query_name: str):
        return get_data(self._package_name, query_name).decode("utf-8")

    @property
    def query_text(self) -> str:
        """Query's SQL code."""
        return self._query_text

    @property
    def description(self) -> str:
        """Query description."""
        return self._description

    @property
    def title(self) -> str:
        """Query title."""
        return self._title

    @property
    def blurb(self) -> str:
        """Query short description. May be empty but is a string."""
        return self._blurb

    @property
    def sproc_return_types(self) -> Tuple[str, str]:
        """Query title."""
        return self._sproc_return_types

    def __post_init__(self):
        """After instance is created, populate the attributes."""
        self._query_text = self._read_text(f"{self.source_name}/{self.source_name}.sql")
        readme_contents = frontmatter.loads(
            self._read_text(f"{self.source_name}/README.md")
        )
        self._description = readme_contents.content
        self._title = str(readme_contents["title"])
        self._blurb = str(readme_contents.get("blurb", ""))
        self._sproc_return_types = tuple(
            dict(readme_contents.get("sproc_return_types", {})).items()
        )

        assert (
            self._title != ""
        ), f"Query title should not be empty. Check frontmatter of {self.source_name} README."

    def __str__(self):
        """Return the query text of the Query."""
        return self.query_text

    @property
    def sproc_name(self) -> str:
        """Return the name of the query's stored procedure."""
        return f"{self._app_name}_{self.source_name}"

    def as_sql_sproc(self) -> str:
        """Return the code to run the query as a stored procedure."""
        # In parts so that python inline-comments are possible
        return "\n".join(
            [
                f"CREATE OR REPLACE PROCEDURE {self.sproc_name} ()",  # these queries don't accept inputs => ()
                f"RETURNS TABLE({', '.join(map(lambda r: f'{r[0]} {r[1]}', self._sproc_return_types))})",
                "LANGUAGE SQL",
                "AS",
                "$$",
                "DECLARE",
                "res RESULTSET;",  # Required syntax for sprocs returning tables?
                "BEGIN",
                f"res :=({''.join(self.query_text.rsplit(';', 1))});",  # Effectively removes last semicolon
                "RETURN TABLE(res);",
                "END",
                "$$",
            ]
        )
