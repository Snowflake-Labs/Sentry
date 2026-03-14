"""Common utilities for Trust Center Extension scanners.

Provides shared schema definition and helper functions for building
scanner results in the Trust Center-compatible format.
"""

from functools import wraps

from snowflake.snowpark.types import ArrayType, IntegerType, StringType, StructField, StructType

# Standard schema for Trust Center scanner results
RESULT_SCHEMA = StructType(
    [
        StructField("risk_id", StringType()),
        StructField("risk_name", StringType()),
        StructField("total_at_risk_count", IntegerType()),
        StructField("scanner_type", StringType()),
        StructField("risk_description", StringType()),
        StructField("suggested_action", StringType()),
        StructField("impact", StringType()),
        StructField("severity", StringType()),
        StructField("at_risk_entities", ArrayType()),
    ]
)


def build_entity(name: str, object_type: str, detail: dict) -> dict:
    """Build an entity dictionary in Trust Center format.

    Args:
        name: The entity name (e.g., user name, role name, query ID)
        object_type: The type of entity (e.g., "USER", "ROLE", "QUERY")
        detail: Dictionary of additional details about the entity

    Returns:
        Dictionary with entity_name, entity_object_type, and entity_detail keys
    """
    return {
        "entity_name": name,
        "entity_object_type": object_type,
        "entity_detail": detail,
    }


def build_result(
    session,
    risk_id: str,
    risk_name: str,
    entities: list,
    risk_description: str,
    suggested_action: str,
    impact: str,
    severity: str = "LOW",
    scanner_type: str = "VULNERABILITY",
):
    """Build a scanner result DataFrame in Trust Center format.

    Args:
        session: Snowpark session
        risk_id: Unique identifier for this risk type
        risk_name: Human-readable name for this risk
        entities: List of at-risk entities (built with build_entity())
        risk_description: Detailed description of the risk (required)
        suggested_action: Recommended action to remediate (required)
        impact: Description of potential impact (required)
        severity: Risk severity (LOW, MEDIUM, HIGH, CRITICAL)
        scanner_type: Type of scanner (VULNERABILITY or DETECTION)

    Returns:
        Snowpark DataFrame with scanner results
    """
    return session.create_dataframe(
        (
            (
                risk_id,
                risk_name,
                len(entities),
                scanner_type,
                risk_description,
                suggested_action,
                impact,
                severity,
                entities,
            ),
        ),
        RESULT_SCHEMA,
    )


def limit_entities(max_count: int):
    """Decorator to limit entities returned by a scanner.

    Args:
        max_count: Maximum number of entities to return

    Returns:
        Decorator function
    """
    def decorator(func):
        @wraps(func)
        def wrapper(session, run_id):
            entities = func(session, run_id)
            return entities[:max_count]
        return wrapper
    return decorator


def scanner(
    risk_id: str,
    risk_name: str,
    risk_description: str = "",
    suggested_action: str = "",
    impact: str = "",
    severity: str = "LOW",
    scanner_type: str = "VULNERABILITY",
):
    """Decorator to wrap entity list into Trust Center result DataFrame.

    Args:
        risk_id: Unique identifier for this risk type
        risk_name: Human-readable name for this risk
        risk_description: Detailed description of the risk
        suggested_action: Recommended action to remediate
        impact: Description of potential impact
        severity: Risk severity (LOW, MEDIUM, HIGH, CRITICAL)
        scanner_type: Type of scanner (default: VULNERABILITY)

    Returns:
        Decorator function
    """
    def decorator(func):
        @wraps(func)
        def wrapper(session, run_id):
            entities = func(session, run_id)
            return build_result(
                session,
                risk_id,
                risk_name,
                entities,
                risk_description,
                suggested_action,
                impact,
                severity,
                scanner_type,
            )
        return wrapper
    return decorator
