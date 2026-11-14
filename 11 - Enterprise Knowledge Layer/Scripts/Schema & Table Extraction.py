"""Phase 1 / Step 1 — Schema & Table Extraction.

Parse all PostgreSQL schemas, CREATE TABLE blocks, and physical columns from
`L&A Data Domain/L&A Data Model - Physical DDL.sql`, then map business columns
1-to-1 by ordinal onto logical attributes from `L&A Data Model - Logical.MD`.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ekl_common import (  # noqa: E402
    attributes_for_table,
    ensure_output_dir,
    harvest_logical_model,
    harvest_physical_model,
    match_entity_name,
    serialize_table,
    write_json,
)


def main() -> None:
    physical = harvest_physical_model()
    logical = harvest_logical_model()
    tables = physical["tables"]
    entities = logical["entities"]
    attributes = logical["attributes"]

    table_payloads = []
    mapped_business_columns = 0
    for table in tables:
        logical_attrs = attributes_for_table(table, entities, attributes)
        matched_entity = match_entity_name(table.table, entities)
        mapped_business_columns += min(len(logical_attrs), table.business_column_count)
        table_payloads.append(
            {
                **serialize_table(table),
                "logical_entity_name": matched_entity.entity_name if matched_entity else None,
                "mapped_logical_attributes": [
                    {
                        "column_order": attr.column_order,
                        "attribute_name": attr.attribute_name,
                        "data_type": attr.data_type,
                        "key": attr.key,
                        "definition": attr.definition,
                    }
                    for attr in logical_attrs
                ],
            }
        )

    payload = {
        "step": "Schema & Table Extraction",
        "source_ddl": "L&A Data Domain/L&A Data Model - Physical DDL.sql",
        "source_logical": "L&A Data Domain/L&A Data Model - Logical.MD",
        "schemas": physical["schemas"],
        "tables": table_payloads,
        "counts": {
            **physical["counts"],
            "logical_entities": logical["counts"]["entities"],
            "logical_attributes": logical["counts"]["attributes"],
            "mapped_business_columns": mapped_business_columns,
        },
    }
    out_path = ensure_output_dir() / "schema_and_table_extraction.json"
    write_json(out_path, payload)
    counts = payload["counts"]
    print("Schema & Table Extraction complete")
    print(f"  schemas            : {counts['schemas']}")
    print(f"  tables             : {counts['tables']}")
    print(f"  total columns      : {counts['columns']}")
    print(f"  business columns   : {counts['business_columns']}")
    print(f"  audit columns      : {counts['audit_columns']}")
    print(f"  mapped logical attrs: {counts['mapped_business_columns']}")
    print(f"  output             : {out_path}")


if __name__ == "__main__":
    main()
