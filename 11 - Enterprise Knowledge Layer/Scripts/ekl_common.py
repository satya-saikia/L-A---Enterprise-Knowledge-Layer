"""Shared harvest utilities for the L&A Enterprise Knowledge Layer workflow."""

from __future__ import annotations

import json
import re
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parent.parent
DATA_DOMAIN = ROOT / "L&A Data Domain"
DDL_PATH = DATA_DOMAIN / "L&A Data Model - Physical DDL.sql"
LOGICAL_PATH = DATA_DOMAIN / "L&A Data Model - Logical.MD"
ONTOLOGY_PATH = DATA_DOMAIN / "L&A - Ontology.MD"
CONCEPTUAL_PATH = DATA_DOMAIN / "L&A Data Model - Conceptual.MD"
OKF_DIR = ROOT / "L&A OKF"
SCRIPTS_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = SCRIPTS_DIR / "output"

AUDIT_COLUMNS = {"created_at", "updated_at"}

DOMAIN_CATALOG: list[dict[str, Any]] = [
    {
        "number": 1,
        "schema": "product",
        "name": "Product",
        "display_name": "Product (Product Catalog, Filings & Crediting/Liquidity Rules)",
        "wiki_file": "01 - OKF - Product.MD",
        "bc_start": 1,
        "bc_end": 20,
    },
    {
        "number": 2,
        "schema": "policy",
        "name": "Policy",
        "display_name": "Policy (Contract & Certificate Administration)",
        "wiki_file": "02 - OKF - Policy.MD",
        "bc_start": 21,
        "bc_end": 42,
    },
    {
        "number": 3,
        "schema": "riders",
        "name": "Riders",
        "display_name": "Riders (Supplemental Benefits & Living/Death Guarantees)",
        "wiki_file": "03 - OKF - Riders.MD",
        "bc_start": 43,
        "bc_end": 61,
    },
    {
        "number": 4,
        "schema": "fund",
        "name": "Fund",
        "display_name": "Fund (Separate Accounts, Dual-Unit Prices & General Account Funds)",
        "wiki_file": "04 - OKF - Fund.MD",
        "bc_start": 62,
        "bc_end": 81,
    },
    {
        "number": 5,
        "schema": "transactions",
        "name": "Transactions",
        "display_name": "Transactions (Policy Financial & Non-Financial Activity)",
        "wiki_file": "05 - OKF - Transactions.MD",
        "bc_start": 82,
        "bc_end": 103,
    },
    {
        "number": 6,
        "schema": "reinsurance",
        "name": "Reinsurance",
        "display_name": "Reinsurance (Ceded & Assumed Risk Management)",
        "wiki_file": "06 - OKF - Reinsurance.MD",
        "bc_start": 104,
        "bc_end": 120,
    },
    {
        "number": 7,
        "schema": "finance",
        "name": "Finance",
        "display_name": "Finance (Insurance Sub-Ledger, General Ledger & Crediting Declarations)",
        "wiki_file": "07 - OKF - Finance.MD",
        "bc_start": 121,
        "bc_end": 140,
    },
    {
        "number": 8,
        "schema": "experience_studies",
        "name": "Experience Studies",
        "display_name": "Experience Studies (Historical Behavioral & Biometric Analytics)",
        "wiki_file": "08 - OKF - Experience Studies.MD",
        "bc_start": 141,
        "bc_end": 158,
    },
    {
        "number": 9,
        "schema": "actuarial",
        "name": "Actuarial",
        "display_name": "Actuarial (Valuation, Reserves, Pricing & Capital Modeling)",
        "wiki_file": "09 - OKF - Actuarial.MD",
        "bc_start": 159,
        "bc_end": 178,
    },
    {
        "number": 10,
        "schema": "agent_and_agency",
        "name": "Agent & Agency",
        "display_name": "Agent & Agency (Distribution, Wealth Management & Compensation)",
        "wiki_file": "10 - OKF - Agent and Agency.MD",
        "bc_start": 179,
        "bc_end": 198,
    },
    {
        "number": 11,
        "schema": "party_customer_and_household",
        "name": "Party, Customer & Household",
        "display_name": "Party, Customer & Household",
        "wiki_file": "11 - OKF - Party Customer and Household.MD",
        "bc_start": 199,
        "bc_end": 218,
    },
    {
        "number": 12,
        "schema": "institutional_plan_and_employer_sponsor",
        "name": "Institutional Plan & Employer Sponsor",
        "display_name": "Institutional Plan & Employer Sponsor",
        "wiki_file": "12 - OKF - Institutional Plan and Employer Sponsor.MD",
        "bc_start": 219,
        "bc_end": 236,
    },
    {
        "number": 13,
        "schema": "underwriting_and_new_business",
        "name": "Underwriting & New Business",
        "display_name": "Underwriting & New Business",
        "wiki_file": "13 - OKF - Underwriting and New Business.MD",
        "bc_start": 237,
        "bc_end": 254,
    },
    {
        "number": 14,
        "schema": "claims_annuitization_and_benefit_payouts",
        "name": "Claims, Annuitization & Benefit Payouts",
        "display_name": "Claims, Annuitization & Benefit Payouts",
        "wiki_file": "14 - OKF - Claims Annuitization and Benefit Payouts.MD",
        "bc_start": 255,
        "bc_end": 272,
    },
    {
        "number": 15,
        "schema": "billing_remittance_and_tax_reporting",
        "name": "Billing, Remittance & Tax Reporting",
        "display_name": "Billing, Remittance & Tax Reporting",
        "wiki_file": "15 - OKF - Billing Remittance and Tax Reporting.MD",
        "bc_start": 273,
        "bc_end": 289,
    },
    {
        "number": 16,
        "schema": "compliance_suitability_and_regulatory_governance",
        "name": "Compliance, Suitability & Regulatory Governance",
        "display_name": "Compliance, Suitability & Regulatory Governance",
        "wiki_file": "16 - OKF - Compliance Suitability and Regulatory Governance.MD",
        "bc_start": 290,
        "bc_end": 305,
    },
]

SCHEMA_TO_DOMAIN = {d["schema"]: d for d in DOMAIN_CATALOG}


@dataclass
class ColumnSpec:
    name: str
    physical_type: str
    nullable: bool
    default: str | None
    ordinal: int
    is_audit: bool


@dataclass
class ConstraintSpec:
    kind: str
    name: str
    definition: str
    columns: list[str] = field(default_factory=list)
    schema: str = ""
    table: str = ""


@dataclass
class TableSpec:
    schema: str
    table: str
    comment: str
    columns: list[ColumnSpec]
    primary_keys: list[ConstraintSpec]
    unique_constraints: list[ConstraintSpec]
    check_constraints: list[ConstraintSpec]

    @property
    def qualified(self) -> str:
        return f"{self.schema}.{self.table}"

    @property
    def business_column_count(self) -> int:
        return sum(1 for c in self.columns if not c.is_audit)

    @property
    def audit_column_count(self) -> int:
        return sum(1 for c in self.columns if c.is_audit)

    @property
    def pk_columns(self) -> list[str]:
        if not self.primary_keys:
            return []
        return self.primary_keys[0].columns


@dataclass
class ForeignKeySpec:
    name: str
    child_schema: str
    child_table: str
    child_column: str
    parent_schema: str
    parent_table: str
    parent_column: str
    update_action: str
    delete_action: str

    @property
    def intra_domain(self) -> bool:
        return self.child_schema == self.parent_schema

    @property
    def join_scope(self) -> str:
        if self.intra_domain:
            return "Intra-Domain"
        return f"Cross-Domain (`{self.parent_schema}`)"

    @property
    def referential_action(self) -> str:
        parts = []
        if self.update_action:
            parts.append(f"ON UPDATE {self.update_action}")
        if self.delete_action:
            parts.append(f"ON DELETE {self.delete_action}")
        return " ".join(parts)

    @property
    def sql_predicate(self) -> str:
        return (
            f"{self.child_schema}.{self.child_table}.{self.child_column} = "
            f"{self.parent_schema}.{self.parent_table}.{self.parent_column}"
        )


@dataclass
class IndexSpec:
    name: str
    schema: str
    table: str
    columns: list[str]
    unique: bool
    definition: str


@dataclass
class LogicalAttribute:
    domain_name: str
    entity_name: str
    attribute_name: str
    definition: str
    data_type: str
    key: str
    column_order: int


@dataclass
class LogicalEntity:
    domain_name: str
    entity_name: str
    definition: str


@dataclass
class BusinessContextRule:
    code: str
    number: int
    title: str
    body: str


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def ensure_output_dir() -> Path:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    return OUTPUT_DIR


def write_json(path: Path, payload: Any) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return path


def strip_md(value: str) -> str:
    return value.replace("**", "").replace("`", "").strip()


def normalize_token(value: str) -> str:
    text = value.lower().replace("&", " and ").replace("/", " ")
    return re.sub(r"[^a-z0-9]", "", text)


def snake_to_title(name: str) -> str:
    return " ".join(part.capitalize() for part in name.split("_"))


def logical_type_from_physical(physical_type: str) -> str:
    upper = physical_type.upper()
    if "TIMESTAMP" in upper:
        return "Timestamp"
    if upper.startswith("DATE"):
        return "Date"
    if "NUMERIC" in upper or "DECIMAL" in upper or "MONEY" in upper:
        return "Decimal"
    if "INT" in upper:
        return "Integer"
    if "BOOL" in upper:
        return "Boolean"
    return "String"


def parse_column_list(raw: str) -> list[str]:
    return [part.strip() for part in raw.split(",") if part.strip()]


def parse_schemas(ddl: str) -> list[dict[str, str]]:
    schemas = []
    for match in re.finditer(
        r"CREATE SCHEMA IF NOT EXISTS (\w+);\s*COMMENT ON SCHEMA \1 IS '([^']*)';",
        ddl,
        flags=re.IGNORECASE,
    ):
        schemas.append({"schema": match.group(1), "comment": match.group(2)})
    return schemas


def _parse_constraint(schema: str, table: str, raw: str) -> ConstraintSpec | None:
    text = raw.strip().rstrip(",")
    pk = re.match(
        r"CONSTRAINT\s+(\w+)\s+PRIMARY KEY\s*\(([^)]+)\)",
        text,
        flags=re.IGNORECASE,
    )
    if pk:
        columns = parse_column_list(pk.group(2))
        return ConstraintSpec(
            kind="PRIMARY KEY",
            name=pk.group(1),
            definition=f"PRIMARY KEY ({', '.join(columns)})",
            columns=columns,
            schema=schema,
            table=table,
        )
    uq = re.match(
        r"CONSTRAINT\s+(\w+)\s+UNIQUE\s*\(([^)]+)\)",
        text,
        flags=re.IGNORECASE,
    )
    if uq:
        columns = parse_column_list(uq.group(2))
        return ConstraintSpec(
            kind="UNIQUE",
            name=uq.group(1),
            definition=f"UNIQUE ({', '.join(columns)})",
            columns=columns,
            schema=schema,
            table=table,
        )
    chk = re.match(
        r"CONSTRAINT\s+(\w+)\s+CHECK\s*\((.+)\)\s*$",
        text,
        flags=re.IGNORECASE | re.DOTALL,
    )
    if chk:
        expr = chk.group(2).strip()
        return ConstraintSpec(
            kind="CHECK",
            name=chk.group(1),
            definition=f"CHECK ({expr})",
            columns=[],
            schema=schema,
            table=table,
        )
    return None


def _parse_column_line(line: str, ordinal: int) -> ColumnSpec | None:
    raw = line.strip().rstrip(",")
    if not raw or raw.upper().startswith("CONSTRAINT"):
        return None
    match = re.match(
        r"^([a-zA-Z_][a-zA-Z0-9_]*)\s+([A-Za-z]+(?:\s+[A-Za-z]+)?(?:\([^)]+\))?)\s*(.*)$",
        raw,
    )
    if not match:
        return None
    name = match.group(1)
    physical_type = re.sub(r"\s+", "", match.group(2).upper()) if "(" in match.group(2) else match.group(2).upper()
    if "(" in match.group(2):
        type_match = re.match(r"^([A-Za-z]+)\s*(\([^)]+\))$", match.group(2).strip(), flags=re.IGNORECASE)
        physical_type = f"{type_match.group(1).upper()}{type_match.group(2)}" if type_match else match.group(2).upper()
    rest = match.group(3).strip()
    nullable = "NOT NULL" not in rest.upper()
    default = None
    default_match = re.search(r"DEFAULT\s+(.+)$", rest, flags=re.IGNORECASE)
    if default_match:
        default = default_match.group(1).strip()
    return ColumnSpec(
        name=name,
        physical_type=physical_type,
        nullable=nullable,
        default=default,
        ordinal=ordinal,
        is_audit=name in AUDIT_COLUMNS,
    )


def parse_tables(ddl: str) -> list[TableSpec]:
    comments = {
        f"{m.group(1)}.{m.group(2)}": m.group(3)
        for m in re.finditer(
            r"COMMENT ON TABLE (\w+)\.(\w+) IS '([^']*)';",
            ddl,
            flags=re.IGNORECASE,
        )
    }
    tables: list[TableSpec] = []
    pattern = re.compile(
        r"CREATE TABLE IF NOT EXISTS (\w+)\.(\w+)\s*\((.*?)\)\s*;",
        flags=re.IGNORECASE | re.DOTALL,
    )
    for match in pattern.finditer(ddl):
        schema, table, body = match.group(1), match.group(2), match.group(3)
        columns: list[ColumnSpec] = []
        pks: list[ConstraintSpec] = []
        uqs: list[ConstraintSpec] = []
        chks: list[ConstraintSpec] = []
        ordinal = 0
        for raw_line in body.splitlines():
            line = raw_line.strip()
            if not line:
                continue
            if line.upper().startswith("CONSTRAINT"):
                constraint = _parse_constraint(schema, table, line)
                if constraint is None:
                    continue
                if constraint.kind == "PRIMARY KEY":
                    pks.append(constraint)
                elif constraint.kind == "UNIQUE":
                    uqs.append(constraint)
                elif constraint.kind == "CHECK":
                    chks.append(constraint)
                continue
            ordinal += 1
            column = _parse_column_line(line, ordinal)
            if column:
                columns.append(column)
        tables.append(
            TableSpec(
                schema=schema,
                table=table,
                comment=comments.get(f"{schema}.{table}", ""),
                columns=columns,
                primary_keys=pks,
                unique_constraints=uqs,
                check_constraints=chks,
            )
        )
    return tables


def parse_foreign_keys(ddl: str) -> list[ForeignKeySpec]:
    fks: list[ForeignKeySpec] = []
    alter_pattern = re.compile(
        r"ALTER TABLE (\w+)\.(\w+)\s+(.*?);",
        flags=re.IGNORECASE | re.DOTALL,
    )
    fk_pattern = re.compile(
        r"ADD CONSTRAINT\s+(\w+)\s+FOREIGN KEY\s*\(([^)]+)\)\s+"
        r"REFERENCES\s+(\w+)\.(\w+)\s*\(([^)]+)\)"
        r"(?:\s+ON UPDATE\s+(\w+))?"
        r"(?:\s+ON DELETE\s+((?:SET NULL)|(?:CASCADE)|(?:RESTRICT)|(?:NO ACTION)))?",
        flags=re.IGNORECASE,
    )
    for alter in alter_pattern.finditer(ddl):
        child_schema, child_table, body = alter.group(1), alter.group(2), alter.group(3)
        for fk in fk_pattern.finditer(body):
            fks.append(
                ForeignKeySpec(
                    name=fk.group(1),
                    child_schema=child_schema,
                    child_table=child_table,
                    child_column=fk.group(2).strip(),
                    parent_schema=fk.group(3),
                    parent_table=fk.group(4),
                    parent_column=fk.group(5).strip(),
                    update_action=(fk.group(6) or "").upper(),
                    delete_action=(fk.group(7) or "").upper(),
                )
            )
    return fks


def parse_indexes(ddl: str) -> list[IndexSpec]:
    indexes: list[IndexSpec] = []
    pattern = re.compile(
        r"CREATE\s+(UNIQUE\s+)?INDEX IF NOT EXISTS (\w+)\s+ON\s+(\w+)\.(\w+)\s*\(([^)]+)\)\s*;",
        flags=re.IGNORECASE,
    )
    for match in pattern.finditer(ddl):
        unique = bool(match.group(1))
        columns = parse_column_list(match.group(5))
        kind = "UNIQUE INDEX" if unique else "INDEX"
        indexes.append(
            IndexSpec(
                name=match.group(2),
                schema=match.group(3),
                table=match.group(4),
                columns=columns,
                unique=unique,
                definition=f"{kind} ({', '.join(columns)})",
            )
        )
    return indexes


def parse_logical_entities(text: str) -> list[LogicalEntity]:
    entities: list[LogicalEntity] = []
    section = text.split("## 1. Logical Entity Catalog", 1)
    if len(section) < 2:
        return entities
    catalog = section[1].split("## 2. Logical Attribute Catalog", 1)[0]
    for line in catalog.splitlines():
        if not line.startswith("|") or line.startswith("| Domain Name") or re.match(r"^\|\s*:?-", line):
            continue
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if len(cells) < 3:
            continue
        domain, entity, definition = (strip_md(cells[0]), strip_md(cells[1]), cells[2].strip())
        if not domain or not entity:
            continue
        entities.append(LogicalEntity(domain_name=domain, entity_name=entity, definition=definition))
    return entities


def parse_logical_attributes(text: str) -> list[LogicalAttribute]:
    attributes: list[LogicalAttribute] = []
    for line in text.splitlines():
        if not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if len(cells) < 7:
            continue
        if cells[0].startswith("Domain Name") or cells[0].startswith(":--") or cells[0].startswith("---"):
            continue
        domain = strip_md(cells[0])
        entity = strip_md(cells[1])
        attribute = strip_md(cells[2])
        if not domain or not entity or not attribute:
            continue
        if domain.lower() == "domain name":
            continue
        try:
            order = int(strip_md(cells[6]))
        except ValueError:
            continue
        attributes.append(
            LogicalAttribute(
                domain_name=domain,
                entity_name=entity,
                attribute_name=attribute,
                definition=cells[3].strip(),
                data_type=strip_md(cells[4]),
                key=strip_md(cells[5]),
                column_order=order,
            )
        )
    return attributes


def parse_ontology_narratives(text: str) -> dict[int, str]:
    narratives: dict[int, str] = {}
    matches = list(
        re.finditer(r"^### 1\.(\d+)\s+Domain[^\n]*\n", text, flags=re.MULTILINE)
    )
    for idx, match in enumerate(matches):
        domain_number = int(match.group(1))
        start = match.end()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else text.find("## 2.", start)
        if end == -1:
            end = len(text)
        narratives[domain_number] = text[start:end].strip()
    return narratives


def parse_business_contexts(text: str) -> list[BusinessContextRule]:
    rules: list[BusinessContextRule] = []
    matches = list(re.finditer(r"^#### (BC-(\d+)):\s*(.+)\s*$", text, flags=re.MULTILINE))
    for idx, match in enumerate(matches):
        start = match.start()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
        body = text[start:end].strip()
        number = int(match.group(2))
        rules.append(
            BusinessContextRule(
                code=match.group(1),
                number=number,
                title=match.group(3).strip(),
                body=body,
            )
        )
    return rules


def match_entity_name(table_name: str, entities: Iterable[LogicalEntity]) -> LogicalEntity | None:
    target = normalize_token(table_name)
    for entity in entities:
        if normalize_token(entity.entity_name) == target:
            return entity
    return None


def table_index_map(indexes: list[IndexSpec]) -> dict[str, list[IndexSpec]]:
    grouped: dict[str, list[IndexSpec]] = {}
    for index in indexes:
        grouped.setdefault(f"{index.schema}.{index.table}", []).append(index)
    return grouped


def fk_by_child(fks: list[ForeignKeySpec]) -> dict[str, list[ForeignKeySpec]]:
    grouped: dict[str, list[ForeignKeySpec]] = {}
    for fk in fks:
        grouped.setdefault(f"{fk.child_schema}.{fk.child_table}", []).append(fk)
    return grouped


def fk_by_parent(fks: list[ForeignKeySpec]) -> dict[str, list[ForeignKeySpec]]:
    grouped: dict[str, list[ForeignKeySpec]] = {}
    for fk in fks:
        grouped.setdefault(f"{fk.parent_schema}.{fk.parent_table}", []).append(fk)
    return grouped


def harvest_physical_model() -> dict[str, Any]:
    ddl = read_text(DDL_PATH)
    schemas = parse_schemas(ddl)
    tables = parse_tables(ddl)
    foreign_keys = parse_foreign_keys(ddl)
    indexes = parse_indexes(ddl)
    return {
        "schemas": schemas,
        "tables": tables,
        "foreign_keys": foreign_keys,
        "indexes": indexes,
        "counts": {
            "schemas": len(schemas),
            "tables": len(tables),
            "columns": sum(len(t.columns) for t in tables),
            "business_columns": sum(t.business_column_count for t in tables),
            "audit_columns": sum(t.audit_column_count for t in tables),
            "primary_keys": sum(len(t.primary_keys) for t in tables),
            "unique_constraints": sum(len(t.unique_constraints) for t in tables),
            "check_constraints": sum(len(t.check_constraints) for t in tables),
            "foreign_keys": len(foreign_keys),
            "intra_domain_fks": sum(1 for fk in foreign_keys if fk.intra_domain),
            "cross_domain_fks": sum(1 for fk in foreign_keys if not fk.intra_domain),
            "indexes": len(indexes),
        },
    }


def harvest_logical_model() -> dict[str, Any]:
    text = read_text(LOGICAL_PATH)
    entities = parse_logical_entities(text)
    attributes = parse_logical_attributes(text)
    return {
        "entities": entities,
        "attributes": attributes,
        "counts": {
            "entities": len(entities),
            "attributes": len(attributes),
        },
    }


def harvest_ontology() -> dict[str, Any]:
    text = read_text(ONTOLOGY_PATH)
    narratives = parse_ontology_narratives(text)
    rules = parse_business_contexts(text)
    return {
        "narratives": narratives,
        "business_contexts": rules,
        "counts": {
            "domain_narratives": len(narratives),
            "business_contexts": len(rules),
        },
    }


def serialize_table(table: TableSpec) -> dict[str, Any]:
    payload = asdict(table)
    payload["qualified"] = table.qualified
    payload["business_column_count"] = table.business_column_count
    payload["audit_column_count"] = table.audit_column_count
    payload["pk_columns"] = table.pk_columns
    return payload


def serialize_fk(fk: ForeignKeySpec) -> dict[str, Any]:
    payload = asdict(fk)
    payload["intra_domain"] = fk.intra_domain
    payload["join_scope"] = fk.join_scope
    payload["referential_action"] = fk.referential_action
    payload["sql_predicate"] = fk.sql_predicate
    return payload


def entity_display_name(table: TableSpec, entities: list[LogicalEntity]) -> str:
    matched = match_entity_name(table.table, entities)
    if matched:
        return matched.entity_name
    return snake_to_title(table.table)


def entity_definition(table: TableSpec, entities: list[LogicalEntity]) -> str:
    matched = match_entity_name(table.table, entities)
    if matched:
        return matched.definition
    return table.comment or f"{snake_to_title(table.table)} physical table in schema `{table.schema}`."


def attributes_for_table(
    table: TableSpec,
    entities: list[LogicalEntity],
    attributes: list[LogicalAttribute],
) -> list[LogicalAttribute]:
    matched = match_entity_name(table.table, entities)
    if not matched:
        return []
    rows = [
        attr
        for attr in attributes
        if normalize_token(attr.entity_name) == normalize_token(matched.entity_name)
    ]
    return sorted(rows, key=lambda item: item.column_order)


def modifier_text(column: ColumnSpec) -> str:
    parts = ["NULL" if column.nullable else "NOT NULL"]
    if column.default:
        parts.append(f"DEFAULT {column.default}")
    return " ".join(parts)


def key_label(column: ColumnSpec, table: TableSpec, outbound_fk_cols: set[str], logical_key: str | None) -> str:
    if column.is_audit:
        return "AUDIT"
    if column.name in table.pk_columns:
        return "PK"
    if column.name in outbound_fk_cols:
        return "FK"
    if logical_key:
        return logical_key
    return "NK"
