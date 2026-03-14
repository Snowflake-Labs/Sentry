"""Common utilities shared across all scanners."""


def build_entity(entity_id: str, entity_name: str, entity_type: str, **details) -> dict:
    """Build an at-risk entity object in the expected format."""
    return {
        "entity_id": entity_id,
        "entity_name": entity_name,
        "entity_object_type": entity_type,
        "entity_detail": details,
    }


def build_result(
    risk_id: str,
    risk_name: str,
    risk_description: str,
    suggested_action: str,
    impact: str,
    severity: str,
    at_risk_entities: list[dict],
) -> dict:
    """Build a scanner result row in the expected format."""
    return {
        "RISK_ID": risk_id,
        "RISK_NAME": risk_name,
        "TOTAL_AT_RISK_COUNT": len(at_risk_entities),
        "SCANNER_TYPE": "VULNERABILITY",
        "RISK_DESCRIPTION": risk_description,
        "SUGGESTED_ACTION": suggested_action,
        "IMPACT": impact,
        "SEVERITY": severity,
        "AT_RISK_ENTITIES": at_risk_entities,
    }
