"""Phase 2 / Step 1 — Foreign Key Graph Extraction.

Parse ALTER TABLE ... ADD CONSTRAINT fk_... FOREIGN KEY statements and classify
each join as intra-domain or cross-domain with exact SQL predicates.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ekl_common import (  # noqa: E402
    ensure_output_dir,
    harvest_physical_model,
    serialize_fk,
    write_json,
)


def main() -> None:
    physical = harvest_physical_model()
    foreign_keys = physical["foreign_keys"]
    payload = {
        "step": "Foreign Key Graph Extraction",
        "source_ddl": "L&A Data Domain/L&A Data Model - Physical DDL.sql",
        "foreign_keys": [serialize_fk(fk) for fk in foreign_keys],
        "intra_domain_foreign_keys": [serialize_fk(fk) for fk in foreign_keys if fk.intra_domain],
        "cross_domain_foreign_keys": [serialize_fk(fk) for fk in foreign_keys if not fk.intra_domain],
        "counts": {
            "foreign_keys": physical["counts"]["foreign_keys"],
            "intra_domain_fks": physical["counts"]["intra_domain_fks"],
            "cross_domain_fks": physical["counts"]["cross_domain_fks"],
        },
    }
    out_path = ensure_output_dir() / "foreign_key_graph_extraction.json"
    write_json(out_path, payload)
    counts = payload["counts"]
    print("Foreign Key Graph Extraction complete")
    print(f"  total FKs          : {counts['foreign_keys']}")
    print(f"  intra-domain FKs   : {counts['intra_domain_fks']}")
    print(f"  cross-domain FKs   : {counts['cross_domain_fks']}")
    print(f"  output             : {out_path}")


if __name__ == "__main__":
    main()
