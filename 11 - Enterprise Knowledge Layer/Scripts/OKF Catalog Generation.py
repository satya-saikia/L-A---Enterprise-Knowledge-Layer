"""Phase 3 — OKF Catalog Generation.

Generate the Master Catalog plus 16 Domain OKF wiki documents from the harvested
physical DDL, logical model, and ontology business-context rules.
"""

from __future__ import annotations

import argparse
import html
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ekl_common import (  # noqa: E402
    DOMAIN_CATALOG,
    OUTPUT_DIR,
    OKF_DIR,
    attributes_for_table,
    ensure_output_dir,
    entity_definition,
    entity_display_name,
    harvest_logical_model,
    harvest_ontology,
    harvest_physical_model,
    key_label,
    logical_type_from_physical,
    modifier_text,
)


def md_cell(value: str) -> str:
    return str(value).replace("|", "\\|").replace("\n", "<br>")


def bc_code(number: int) -> str:
    return f"BC-{number:03d}"


def url_encode_wiki(name: str) -> str:
    return name.replace(" ", "%20")


def tables_for_schema(tables, schema: str):
    return [table for table in tables if table.schema == schema]


def indexes_for_schema(indexes, schema: str):
    return [index for index in indexes if index.schema == schema]


def outbound_fks(fks, schema: str):
    return [fk for fk in fks if fk.child_schema == schema]


def inbound_cross_fks(fks, schema: str):
    return [fk for fk in fks if fk.parent_schema == schema and fk.child_schema != schema]


def inbound_all_fks(fks, schema: str):
    return [fk for fk in fks if fk.parent_schema == schema]


def domain_stats(domain, tables, fks, indexes) -> dict:
    schema = domain["schema"]
    schema_tables = tables_for_schema(tables, schema)
    out_fks = outbound_fks(fks, schema)
    in_cross = inbound_cross_fks(fks, schema)
    schema_indexes = indexes_for_schema(indexes, schema)
    business_cols = sum(table.business_column_count for table in schema_tables)
    total_cols = sum(len(table.columns) for table in schema_tables)
    return {
        "tables": len(schema_tables),
        "business_cols": business_cols,
        "total_cols": total_cols,
        "outbound_fks": len(out_fks),
        "inbound_cross_fks": len(in_cross),
        "inbound_all_fks": len(inbound_all_fks(fks, schema)),
        "indexes": len(schema_indexes),
        "bc_count": domain["bc_end"] - domain["bc_start"] + 1,
    }


def mermaid_for_schema(schema: str, tables, fks, entities) -> str:
    tables_by_q = {table.qualified: table for table in tables}
    lines = ["```mermaid", "erDiagram"]
    relevant = [
        fk
        for fk in fks
        if fk.child_schema == schema or fk.parent_schema == schema
    ]
    for fk in relevant:
        parent = tables_by_q.get(f"{fk.parent_schema}.{fk.parent_table}")
        child = tables_by_q.get(f"{fk.child_schema}.{fk.child_table}")
        parent_label = entity_display_name(parent, entities) if parent else fk.parent_table
        child_label = entity_display_name(child, entities) if child else fk.child_table
        lines.append(
            f'    "{parent_label} ({fk.parent_schema}.{fk.parent_table})" '
            f'||--o{{ "{child_label} ({fk.child_schema}.{fk.child_table})" : '
            f'"{fk.child_column}"'
        )
    lines.append("```")
    return "\n".join(lines)


def constraint_names(table) -> str:
    names = (
        [item.name for item in table.primary_keys]
        + [item.name for item in table.unique_constraints]
        + [item.name for item in table.check_constraints]
    )
    return ", ".join(f"`{name}`" for name in names) if names else "—"


def canonical_sql(schema: str, tables) -> str:
    schema_tables = tables_for_schema(tables, schema)
    if not schema_tables:
        return "-- no tables harvested"
    table = schema_tables[0]
    select_cols = ",\n    ".join(f"t0.{col.name}" for col in table.columns)
    return (
        f"-- Canonical Verified Join Pattern for schema `{schema}`\n"
        f"SELECT\n    {select_cols}\n"
        f"FROM {table.qualified} t0\n"
        f"ORDER BY t0.{table.pk_columns[0] if table.pk_columns else table.columns[0].name}\n"
        "LIMIT 100;"
    )


def render_master_catalog(tables, fks, indexes, ontology) -> str:
    business_cols = sum(table.business_column_count for table in tables)
    total_cols = sum(len(table.columns) for table in tables)
    pks = sum(len(table.primary_keys) for table in tables)
    uqs = sum(len(table.unique_constraints) for table in tables)
    chks = sum(len(table.check_constraints) for table in tables)
    intra = sum(1 for fk in fks if fk.intra_domain)
    cross = sum(1 for fk in fks if not fk.intra_domain)
    bc_count = ontology["counts"]["business_contexts"]

    rows = []
    for domain in DOMAIN_CATALOG:
        stats = domain_stats(domain, tables, fks, indexes)
        wiki = domain["wiki_file"]
        rows.append(
            "| **{num:02d}** | [`{wiki}`](./{href}) | **{name}** | `{schema}` | {tables} | {biz} | {tot} | {out} | {inc} | {idx} | `{start}` – `{end}` ({n}) |".format(
                num=domain["number"],
                wiki=wiki,
                href=url_encode_wiki(wiki),
                name=domain["name"],
                schema=domain["schema"],
                tables=stats["tables"],
                biz=stats["business_cols"],
                tot=stats["total_cols"],
                out=stats["outbound_fks"],
                inc=stats["inbound_cross_fks"],
                idx=stats["indexes"],
                start=bc_code(domain["bc_start"]),
                end=bc_code(domain["bc_end"]),
                n=stats["bc_count"],
            )
        )
    total_stats_tables = sum(domain_stats(d, tables, fks, indexes)["tables"] for d in DOMAIN_CATALOG)
    total_biz = sum(domain_stats(d, tables, fks, indexes)["business_cols"] for d in DOMAIN_CATALOG)
    total_tot = sum(domain_stats(d, tables, fks, indexes)["total_cols"] for d in DOMAIN_CATALOG)
    total_out = sum(domain_stats(d, tables, fks, indexes)["outbound_fks"] for d in DOMAIN_CATALOG)
    total_in = sum(domain_stats(d, tables, fks, indexes)["inbound_cross_fks"] for d in DOMAIN_CATALOG)
    total_idx = sum(domain_stats(d, tables, fks, indexes)["indexes"] for d in DOMAIN_CATALOG)

    hub_lines = []
    inbound_by_parent = {}
    for fk in fks:
        key = f"{fk.parent_schema}.{fk.parent_table}"
        inbound_by_parent.setdefault(key, []).append(fk)
    ranked = sorted(inbound_by_parent.items(), key=lambda item: len(item[1]), reverse=True)[:5]
    for idx, (qualified, inbound) in enumerate(ranked, start=1):
        children = ", ".join(
            f"`{fk.child_schema}.{fk.child_table}`" for fk in inbound
        )
        pk = inbound[0].parent_column
        hub_lines.append(
            f"{idx}. **`{qualified}` (`{pk}`)** referenced by **{len(inbound)} inbound Foreign Keys** across {children}."
        )

    return f"""# L&A Ontology Knowledge Framework (OKF) — Master Catalog & Cross-Domain Relational Lineage

| OKF Master Catalog Attribute | Value |
| :--- | :--- |
| **OKF Master Index Document** | `L&A OKF/00 - L&A OKF Master Catalog & Cross-Domain Lineage.MD` |
| **Target Database Platform** | Amazon RDS Aurora PostgreSQL (PostgreSQL 15/16 Compatible) |
| **Enterprise Data Domains** | **16 Core Domains / Physical Database Schemas** |
| **Total Logical Entities / Physical Tables** | **{len(tables)} Tables** |
| **Total Physical Columns Harvested** | **{total_cols} Columns** (`{business_cols}` Business Attributes + `{total_cols - business_cols}` Audit Timestamps) |
| **Total Declarative Table Constraints** | **{pks + uqs + chks} Constraints** (`{pks}` Primary Keys + `{uqs}` Unique Constraints + `{chks}` Check Constraints) |
| **Total Relational Foreign Key Joins** | **{len(fks)} Foreign Key Constraints** (`{intra}` Intra-Domain Joins + `{cross}` Cross-Domain Joins) |
| **Total Performance Indexes** | **{len(indexes)} B-Tree & Composite Indexes** |
| **Total Inherited Business Context Rules** | **{bc_count} Business Contexts (`BC-001` through `BC-305`)** |
| **Source Knowledge Layer Artifacts** | `L&A Data Domain/L&A - Ontology.MD`, `L&A Data Domain/L&A Data Model - Logical.MD`, `L&A Data Domain/L&A Data Model - Physical DDL.sql`, `L&A Data Domain/L&A Data Model - Conceptual.MD` |

---

## 1. Executive Summary of the L&A Ontology Knowledge Framework (OKF)

The **Life & Annuity (L&A) Ontology Knowledge Framework (`OKF`)** is the authoritative enterprise data wiki and AI-agent semantic catalog bridging high-level business ontology (`L&A - Ontology.MD`) with low-level physical database implementation (`L&A Data Model - Physical DDL.sql`).

Every Domain OKF document (`01` through `16`) unites six layers of metadata in one place:
1. **Domain Executive Ontology Narrative**
2. **Physical Schema & Logical Entity Catalog**
3. **Relational Join Mining & Foreign Key Topology**
4. **Attribute-to-Column Dictionary & DDL Constraints**
5. **Inherited Business Context Ontology Rules (`BC-001` to `BC-305`)**
6. **Canonical AI Agent SQL Query Patterns**

---

## 2. Master Directory of All 16 Domain OKF Wiki Catalogs

| Domain # | OKF Wiki Document | Enterprise Data Domain Name | Physical PostgreSQL Schema | Tables | Business Cols | Total Cols | Outbound FKs | Inbound FKs | Indexes | Business Contexts (`BC-XXX`) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{chr(10).join(rows)}
| **TOTAL** | **16 Domain OKF Documents + 1 Master Catalog** | **All 16 Enterprise L&A Domains** | **16 Schemas** | **{total_stats_tables}** | **{total_biz}** | **{total_tot}** | **{total_out}** | **{total_in}** | **{total_idx}** | **`BC-001` – `BC-305` ({bc_count})** |

---

## 3. Enterprise Cross-Domain Relational Hub Topology

Across the {len(fks)} Foreign Key relationships in the physical database, the highest-degree parent hubs are:

{chr(10).join(hub_lines)}
"""


def render_column_dictionary(table, entities, attributes, outbound_fk_cols) -> str:
    logical_attrs = attributes_for_table(table, entities, attributes)
    attr_by_ord = {attr.column_order: attr for attr in logical_attrs}
    rows = []
    for column in table.columns:
        logical = attr_by_ord.get(column.ordinal) if not column.is_audit else None
        if column.is_audit:
            logical_name = (
                "Record Created Timestamp (Audit)"
                if column.name == "created_at"
                else "Record Updated Timestamp (Audit)"
            )
            definition = (
                "System audit timestamp recording when the physical row was initially inserted into the Aurora PostgreSQL table."
                if column.name == "created_at"
                else "System audit timestamp recording when the physical row was last modified in the Aurora PostgreSQL table."
            )
            logical_type = "Timestamp"
            logical_key = "AUDIT"
        else:
            logical_name = logical.attribute_name if logical else column.name.replace("_", " ").title()
            definition = logical.definition if logical else ""
            logical_type = logical.data_type if logical else logical_type_from_physical(column.physical_type)
            logical_key = logical.key if logical else None
        key = key_label(column, table, outbound_fk_cols, logical_key)
        rows.append(
            "| **{ord}** | **{lname}** | `{pname}` | {ltype} | `{ptype}` | **{key}** | `{mods}` | {defn} |".format(
                ord=column.ordinal,
                lname=md_cell(logical_name),
                pname=column.name,
                ltype=md_cell(logical_type),
                ptype=column.physical_type,
                key=key,
                mods=md_cell(modifier_text(column)),
                defn=md_cell(definition),
            )
        )
    return "\n".join(rows)


def render_constraint_table(table, table_fks, table_indexes) -> str:
    rows = []
    for item in table.primary_keys:
        rows.append(f"| **PRIMARY KEY** | `{item.name}` | `{item.definition}` |")
    for item in table.unique_constraints:
        rows.append(f"| **UNIQUE** | `{item.name}` | `{item.definition}` |")
    for item in table.check_constraints:
        rows.append(f"| **CHECK** | `{item.name}` | `{item.definition}` |")
    for fk in table_fks:
        rows.append(
            f"| **FOREIGN KEY** | `{fk.name}` | `FOREIGN KEY ({fk.child_column}) REFERENCES "
            f"{fk.parent_schema}.{fk.parent_table} ({fk.parent_column}) {fk.referential_action}` |"
        )
    for index in table_indexes:
        rows.append(f"| **INDEX** | `{index.name}` | `{index.definition}` |")
    if not rows:
        return "_No table-level constraints or indexes harvested._"
    header = (
        "| Constraint / Index Category | Identifier Name | Definition / Target Columns & Referential Integrity Rule |\n"
        "| :--- | :--- | :--- |\n"
    )
    return header + "\n".join(rows)


def render_domain_wiki(domain, tables, fks, indexes, entities, attributes, narratives, rules) -> str:
    schema = domain["schema"]
    schema_tables = tables_for_schema(tables, schema)
    stats = domain_stats(domain, tables, fks, indexes)
    out_fks = outbound_fks(fks, schema)
    in_fks = inbound_cross_fks(fks, schema)
    schema_indexes = indexes_for_schema(indexes, schema)
    narrative = narratives.get(domain["number"], "")
    domain_rules = [rule for rule in rules if domain["bc_start"] <= rule.number <= domain["bc_end"]]

    catalog_rows = []
    for idx, table in enumerate(schema_tables, start=1):
        catalog_rows.append(
            "| **{d}.{i}** | **{ename}** | `{q}` | `{pk}` | {biz} | {aud} | {cons} | {defn} |".format(
                d=domain["number"],
                i=idx,
                ename=md_cell(entity_display_name(table, entities)),
                q=table.qualified,
                pk=", ".join(table.pk_columns) if table.pk_columns else "",
                biz=table.business_column_count,
                aud=table.audit_column_count,
                cons=constraint_names(table),
                defn=md_cell(entity_definition(table, entities)),
            )
        )

    outbound_rows = []
    for fk in out_fks:
        outbound_rows.append(
            "| `{name}` | `{child}` | `{col}` | {scope} | `{parent}` | `{pk}` | `{action}` | `{pred}` |".format(
                name=fk.name,
                child=f"{fk.child_schema}.{fk.child_table}",
                col=fk.child_column,
                scope=fk.join_scope,
                parent=f"{fk.parent_schema}.{fk.parent_table}",
                pk=fk.parent_column,
                action=fk.referential_action,
                pred=fk.sql_predicate,
            )
        )

    inbound_rows = []
    for fk in in_fks:
        inbound_rows.append(
            "| `{name}` | `{schema}` | `{child}` | `{col}` | `{parent}` | `{pk}` | `{action}` | `{pred}` |".format(
                name=fk.name,
                schema=fk.child_schema,
                child=f"{fk.child_schema}.{fk.child_table}",
                col=fk.child_column,
                parent=f"{fk.parent_schema}.{fk.parent_table}",
                pk=fk.parent_column,
                action=fk.referential_action,
                pred=fk.sql_predicate,
            )
        )

    table_sections = []
    for idx, table in enumerate(schema_tables, start=1):
        outbound_fk_cols = {fk.child_column for fk in out_fks if fk.child_table == table.table}
        table_fks = [fk for fk in out_fks if fk.child_table == table.table]
        table_indexes = [index for index in schema_indexes if index.table == table.table]
        table_sections.append(
            f"""### 4.{idx} Logical Entity: `{entity_display_name(table, entities)}` <-> Physical Table: `{table.qualified}`

- **Business & Technical Purpose**: {entity_definition(table, entities)}
- **PostgreSQL Catalog Comment**: *"{html.escape(table.comment)}"*
- **Primary Key**: `{', '.join(table.pk_columns) if table.pk_columns else ''}`

#### Attribute-to-Column Schema Mapping & Business Dictionary

| Ord | Logical Attribute Name | Physical Column Name | Logical Type | Physical PostgreSQL Type | Key | Column Modifiers / Default | Business Definition, Domain Semantics & Sample Values |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{render_column_dictionary(table, entities, attributes, outbound_fk_cols)}

#### Declarative DDL Constraints & Indexes on `{table.qualified}`

{render_constraint_table(table, table_fks, table_indexes)}
"""
        )

    rule_blocks = "\n\n".join(rule.body for rule in domain_rules) if domain_rules else "_No inherited business context rules harvested for this domain._"

    outbound_table = (
        "| FK Constraint Name | Child Table | Child FK Column | Join Scope | Parent Referenced Table | Parent PK Column | Referential Action | Exact SQL Join Predicate |\n"
        "| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |\n"
        + "\n".join(outbound_rows)
        if outbound_rows
        else "_No outbound foreign keys._"
    )
    inbound_table = (
        "| FK Constraint Name | Referencing Child Schema | Referencing Child Table | Child FK Column | Referenced Target Table | Target PK Column | Referential Action | Exact SQL Join Predicate |\n"
        "| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |\n"
        + "\n".join(inbound_rows)
        if inbound_rows
        else "_No inbound cross-domain foreign keys._"
    )

    return f"""# L&A Ontology Knowledge Framework (OKF) — Domain {domain['number']}: {domain['display_name']}

| OKF Metadata Attribute | Value |
| :--- | :--- |
| **OKF Catalog Document** | `L&A OKF/{domain['wiki_file']}` |
| **Enterprise Data Domain** | **Domain {domain['number']}: {domain['display_name']}** |
| **Target Physical Database Engine** | Amazon RDS Aurora PostgreSQL (PostgreSQL 15/16 Compatible) |
| **Physical Database Schema** | `{schema}` |
| **Domain Table Count** | **{stats['tables']} Physical Tables / Logical Entities** |
| **Outbound Foreign Key Joins** | **{stats['outbound_fks']} Foreign Key Relationships** (Intra-Domain & Cross-Domain) |
| **Inbound Foreign Key Joins** | **{stats['inbound_cross_fks']} Cross-Domain Referencing Relationships** |
| **Performance Indexes** | **{stats['indexes']} B-Tree & Composite Indexes** |
| **Inherited Business Context Rules** | `{bc_code(domain['bc_start'])}` **through** `{bc_code(domain['bc_end'])}` **({stats['bc_count']} Rules)** |
| **Source Knowledge Layer Artifacts** | `L&A - Ontology.MD`, `L&A Data Model - Logical.MD`, `L&A Data Model - Physical DDL.sql`, `L&A Data Model - Conceptual.MD` |

---

## 1. Domain Executive Ontology & Business Context Overview

{narrative}

---

## 2. Physical Schema & Logical Entity Architecture Catalog (Schema: `{schema}`)

| # | Logical Entity Name | Physical Table Name (`schema.table`) | Primary Key Column (`PK`) | Business Cols | Audit Cols | Constraints (`PK`/`UQ`/`CHK`) | Logical Entity & Physical Table Definition |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
{chr(10).join(catalog_rows)}

---

## 3. Relational Join Mining & Foreign Key Topology

### 3.1 Entity-Relationship & Foreign Key Join Diagram (Mermaid)

{mermaid_for_schema(schema, tables, fks, entities)}

### 3.2 Outbound Foreign Key Join Matrix (Tables in `{schema}` Referencing Parent Entities)

{outbound_table}

### 3.3 Inbound Cross-Domain Foreign Key Join Matrix (External Schemas Referencing `{schema}`)

{inbound_table}

---

## 4. Detailed Table-by-Table Schema, Column Dictionary & DDL Constraints

{chr(10).join(table_sections)}

---

## 5. Inherited Business Context Ontology Rules (`{bc_code(domain['bc_start'])}` – `{bc_code(domain['bc_end'])}`)

{rule_blocks}

---

## 6. Canonical AI Agent SQL Query Patterns & Join Recipes (`{schema}`)

When generating SQL queries against the `{schema}` schema, AI agents must use explicit schema-qualified table names, enforce active status / point-in-time `valuation_date` filters, and pre-aggregate `1:M` child tables in Common Table Expressions (`CTE`s) prior to joining to avoid Cartesian fan-out:

```sql
{canonical_sql(schema, tables)}
```
"""


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate L&A OKF catalog markdown files.")
    parser.add_argument(
        "--write-source",
        action="store_true",
        help="Write generated wikis into L&A OKF/ in addition to Scripts/output/L&A OKF/.",
    )
    args = parser.parse_args()

    physical = harvest_physical_model()
    logical = harvest_logical_model()
    ontology = harvest_ontology()
    tables = physical["tables"]
    fks = physical["foreign_keys"]
    indexes = physical["indexes"]
    entities = logical["entities"]
    attributes = logical["attributes"]
    narratives = ontology["narratives"]
    rules = ontology["business_contexts"]

    out_okf = ensure_output_dir() / "L&A OKF"
    out_okf.mkdir(parents=True, exist_ok=True)
    destinations = [out_okf]
    if args.write_source:
        OKF_DIR.mkdir(parents=True, exist_ok=True)
        destinations.append(OKF_DIR)

    master_name = "00 - L&A OKF Master Catalog & Cross-Domain Lineage.MD"
    master_text = render_master_catalog(tables, fks, indexes, ontology)
    written = []
    for dest in destinations:
        path = dest / master_name
        path.write_text(master_text, encoding="utf-8")
        written.append(path)

    for domain in DOMAIN_CATALOG:
        wiki_text = render_domain_wiki(
            domain, tables, fks, indexes, entities, attributes, narratives, rules
        )
        for dest in destinations:
            path = dest / domain["wiki_file"]
            path.write_text(wiki_text, encoding="utf-8")
            written.append(path)

    manifest = {
        "step": "OKF Catalog Generation",
        "files_written": [str(path) for path in written],
        "counts": {
            "okf_files": 17,
            "domain_wikis": 16,
            "business_contexts_inherited": ontology["counts"]["business_contexts"],
            **physical["counts"],
        },
    }
    manifest_path = OUTPUT_DIR / "okf_catalog_generation.json"
    manifest_path.write_text(
        __import__("json").dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print("OKF Catalog Generation complete")
    print(f"  domain wikis       : 16")
    print(f"  master catalog     : 1")
    print(f"  business contexts  : {ontology['counts']['business_contexts']}")
    print(f"  default output     : {out_okf}")
    if args.write_source:
        print(f"  source OKF folder  : {OKF_DIR}")
    print(f"  manifest           : {manifest_path}")


if __name__ == "__main__":
    main()
