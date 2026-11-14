"""Phase 2 / Step 2 — Enterprise Hub Identification & Chasm-Trap Guardrails.

Compute inbound/outbound join degree for every table, identify cross-domain
hubs, emit Mermaid erDiagram edges, and document chasm-trap SQL guardrails.
"""

from __future__ import annotations

import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ekl_common import (  # noqa: E402
    DOMAIN_CATALOG,
    ensure_output_dir,
    entity_display_name,
    harvest_logical_model,
    harvest_physical_model,
    serialize_fk,
    write_json,
)


def mermaid_edge(fk, tables_by_q, entities) -> str:
    parent = tables_by_q.get(f"{fk.parent_schema}.{fk.parent_table}")
    child = tables_by_q.get(f"{fk.child_schema}.{fk.child_table}")
    parent_label = entity_display_name(parent, entities) if parent else fk.parent_table
    child_label = entity_display_name(child, entities) if child else fk.child_table
    return (
        f'    "{parent_label} ({fk.parent_schema}.{fk.parent_table})" '
        f'||--o{{ "{child_label} ({fk.child_schema}.{fk.child_table})" : '
        f'"{fk.child_column}"'
    )


def main() -> None:
    physical = harvest_physical_model()
    logical = harvest_logical_model()
    tables = physical["tables"]
    fks = physical["foreign_keys"]
    entities = logical["entities"]
    tables_by_q = {table.qualified: table for table in tables}

    degrees: dict[str, dict] = {}
    for table in tables:
        inbound = [fk for fk in fks if f"{fk.parent_schema}.{fk.parent_table}" == table.qualified]
        outbound = [fk for fk in fks if f"{fk.child_schema}.{fk.child_table}" == table.qualified]
        inbound_intra = [fk for fk in inbound if fk.intra_domain]
        inbound_cross = [fk for fk in inbound if not fk.intra_domain]
        degrees[table.qualified] = {
            "schema": table.schema,
            "table": table.table,
            "logical_entity": entity_display_name(table, entities),
            "pk_columns": table.pk_columns,
            "outbound_fk_count": len(outbound),
            "inbound_fk_count": len(inbound),
            "inbound_intra_domain_fk_count": len(inbound_intra),
            "inbound_cross_domain_fk_count": len(inbound_cross),
            "outbound": [serialize_fk(fk) for fk in outbound],
            "inbound": [serialize_fk(fk) for fk in inbound],
        }

    ranked = sorted(
        degrees.values(),
        key=lambda item: (item["inbound_fk_count"], item["inbound_cross_domain_fk_count"]),
        reverse=True,
    )
    hubs = ranked[:5]

    chasm_traps = []
    for hub in hubs:
        high_fanout_children = [
            fk
            for fk in fks
            if f"{fk.parent_schema}.{fk.parent_table}" == f"{hub['schema']}.{hub['table']}"
        ]
        if len(high_fanout_children) < 2:
            continue
        child_tables = sorted({f"{fk.child_schema}.{fk.child_table}" for fk in high_fanout_children})
        chasm_traps.append(
            {
                "hub": f"{hub['schema']}.{hub['table']}",
                "logical_entity": hub["logical_entity"],
                "risk": (
                    "Joining two or more 1:M child tables of this hub in a single FROM/JOIN "
                    "graph produces a Cartesian fan-out (chasm trap). Pre-aggregate each "
                    "child grain in CTEs before joining back to the hub."
                ),
                "child_tables": child_tables,
                "guardrail_sql_pattern": (
                    "WITH child_a AS (SELECT {pk}, COUNT(*) AS metric_a "
                    "FROM {child_a} GROUP BY {pk}), "
                    "child_b AS (SELECT {pk}, COUNT(*) AS metric_b "
                    "FROM {child_b} GROUP BY {pk}) "
                    "SELECT hub.*, child_a.metric_a, child_b.metric_b "
                    "FROM {hub} hub "
                    "LEFT JOIN child_a ON child_a.{pk} = hub.{pk} "
                    "LEFT JOIN child_b ON child_b.{pk} = hub.{pk}"
                ).format(
                    pk=hub["pk_columns"][0] if hub["pk_columns"] else "identifier",
                    child_a=child_tables[0],
                    child_b=child_tables[1] if len(child_tables) > 1 else child_tables[0],
                    hub=f"{hub['schema']}.{hub['table']}",
                ),
            }
        )

    mermaid_lines = ["erDiagram"]
    for fk in fks:
        mermaid_lines.append(mermaid_edge(fk, tables_by_q, entities))

    domain_join_predicates = defaultdict(list)
    for domain in DOMAIN_CATALOG:
        schema = domain["schema"]
        for fk in fks:
            if fk.child_schema == schema or fk.parent_schema == schema:
                domain_join_predicates[schema].append(fk.sql_predicate)

    payload = {
        "step": "Enterprise Hub Identification & Chasm-Trap Guardrails",
        "hubs": hubs,
        "table_degrees": degrees,
        "chasm_trap_guardrails": chasm_traps,
        "enterprise_mermaid_erdiagram": "\n".join(mermaid_lines),
        "domain_sql_join_predicates": dict(domain_join_predicates),
        "counts": {
            "tables": len(tables),
            "foreign_keys": len(fks),
            "identified_hubs": len(hubs),
        },
    }
    out_path = ensure_output_dir() / "enterprise_hub_identification.json"
    write_json(out_path, payload)
    print("Enterprise Hub Identification & Chasm-Trap Guardrails complete")
    print("  primary hubs:")
    for hub in hubs:
        print(
            f"    {hub['schema']}.{hub['table']}: "
            f"{hub['inbound_fk_count']} inbound "
            f"({hub['inbound_intra_domain_fk_count']} intra / "
            f"{hub['inbound_cross_domain_fk_count']} cross)"
        )
    print(f"  chasm-trap hubs   : {len(chasm_traps)}")
    print(f"  output            : {out_path}")


if __name__ == "__main__":
    main()
