"""Phase 1 / Step 2 — Declarative Constraint & Index Extraction.

Harvest PRIMARY KEY, UNIQUE, CHECK, and CREATE INDEX statements from the
physical DDL and emit a constraint catalog grouped by schema.table.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from dataclasses import asdict

from ekl_common import (  # noqa: E402
    ensure_output_dir,
    harvest_physical_model,
    write_json,
)


def main() -> None:
    physical = harvest_physical_model()
    tables = physical["tables"]
    indexes = physical["indexes"]

    by_table: dict[str, dict] = {}
    for table in tables:
        qualified = table.qualified
        by_table[qualified] = {
            "schema": table.schema,
            "table": table.table,
            "primary_keys": [asdict(item) for item in table.primary_keys],
            "unique_constraints": [asdict(item) for item in table.unique_constraints],
            "check_constraints": [asdict(item) for item in table.check_constraints],
            "indexes": [],
        }

    unmatched_indexes = []
    for index in indexes:
        qualified = f"{index.schema}.{index.table}"
        if qualified in by_table:
            by_table[qualified]["indexes"].append(asdict(index))
        else:
            unmatched_indexes.append(asdict(index))

    payload = {
        "step": "Declarative Constraint & Index Extraction",
        "source_ddl": "L&A Data Domain/L&A Data Model - Physical DDL.sql",
        "tables": by_table,
        "unmatched_indexes": unmatched_indexes,
        "counts": {
            "primary_keys": physical["counts"]["primary_keys"],
            "unique_constraints": physical["counts"]["unique_constraints"],
            "check_constraints": physical["counts"]["check_constraints"],
            "table_constraints": (
                physical["counts"]["primary_keys"]
                + physical["counts"]["unique_constraints"]
                + physical["counts"]["check_constraints"]
            ),
            "indexes": physical["counts"]["indexes"],
        },
    }
    out_path = ensure_output_dir() / "declarative_constraint_and_index_extraction.json"
    write_json(out_path, payload)
    counts = payload["counts"]
    print("Declarative Constraint & Index Extraction complete")
    print(f"  primary keys       : {counts['primary_keys']}")
    print(f"  unique constraints : {counts['unique_constraints']}")
    print(f"  check constraints  : {counts['check_constraints']}")
    print(f"  table constraints  : {counts['table_constraints']}")
    print(f"  indexes            : {counts['indexes']}")
    print(f"  output             : {out_path}")


if __name__ == "__main__":
    main()
