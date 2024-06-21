"""Interfaces between files and tiles/stored procedures."""

import dataclasses
from pkgutil import get_data
from typing import Any, ClassVar, Optional, Tuple, Union

from pydantic import BaseModel, ConfigDict
from pydantic.fields import Field

from vendored.python_frontmatter import frontmatter

OptionalTuple = Optional[Union[Tuple[str, ...], str]]


class QueryMetadata(BaseModel):
    """Class that hosts the extraction and validation of the query metadata.

    If adding a new field, make sure that:
    - The parametrized "test_metadata_types" is expanded or a dedicated test is added in `test_classes.py`
    - All tests pass
    """

    tile_identifier: str = Field(alias="Tile Identifier")
    title: str
    blurb: str = Field(default="")
    # TODO: this is completely separate from the classes in `tiles.py`.
    dashboard: str = Field(alias="Dashboard")
    security_features_checklist: OptionalTuple = Field(
        alias="Security Features Checklist", default_factory=tuple
    )
    nist_800_53: OptionalTuple = Field(alias="NIST 800-53", default_factory=tuple)
    nist_800_171: OptionalTuple = Field(alias="NIST 800-171", default_factory=tuple)
    hitrust_csf_v9: OptionalTuple = Field(alias="HITRUST CSF v9", default_factory=tuple)
    mitre_attack_saas: OptionalTuple = Field(
        alias="MITRE ATT&CK (SaaS)", default_factory=tuple
    )

    # Incoming data is from YAML. Values need to be cast to str before validation
    model_config = ConfigDict(coerce_numbers_to_str=True)

    def model_post_init(self, __context: Any) -> None:
        """Perform data normalization post-init."""
        for field in [
            "security_features_checklist",
            "nist_800_53",
            "nist_800_171",
            "hitrust_csf_v9",
            "mitre_attack_saas",
        ]:
            field_val = getattr(self, field)

            # Make sure
            if field_val == ():
                setattr(self, field, None)

            # If the tuple has only one element, unwrap it
            if field_val is not None and len(field_val) == 1:
                setattr(self, field, field_val[0])


@dataclasses.dataclass
class Query:
    """Proxy for the .sql and the document file."""

    source_name: str
    _query_text: str = None
    _description: str = None
    metadata: QueryMetadata = None

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
        self._sproc_return_types = tuple(
            dict(readme_contents.get("sproc_return_types", {})).items()
        )

        self.metadata = QueryMetadata(**dict(readme_contents))

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

    # def __getattr__(self, item):
    def __getattribute__(self, item):
        """If the property is not found in the base class -- try searching for it in the metadata.

        This is better than having the call site care about self.metadata.$FIELD_NAME.

        Note the "object" call below, it prevents infinite recursion.
        """
        try:
            return object.__getattribute__(self, item)
        except AttributeError:
            return object.__getattribute__(self.metadata, item)
