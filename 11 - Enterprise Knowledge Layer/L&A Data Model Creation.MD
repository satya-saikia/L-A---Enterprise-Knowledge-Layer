# Enterprise Life & Annuity (L&A) Insurance Knowledge Layer — End-to-End Data Model & Ontology Creation Playbook

## 1. Executive Objective & Enterprise Architectural Vision

The objective of this initiative is to design and generate a comprehensive, enterprise-grade **Life, Annuity, and Institutional Retirement Insurance Organization Knowledge Layer** spanning four cohesive architectural deliverables:
1. **Conceptual Data Model** (`Output/L&A Data Model - Conceptual.MD`)
2. **Logical Data Model** (`Output/L&A Data Model - Logical.MD`)
3. **Physical Database DDL** (`Output/L&A Data Model - Physical DDL.sql`)
4. **Enterprise Business Ontology for AI Agent Training** (`Output/L&A - Ontology.MD`)

Together, these four artifacts establish a unified semantic and physical foundation capable of supporting operational policy administration, institutional retirement recordkeeping, actuarial valuation, statutory/GAAP financial reporting, multi-channel producer compensation, regulatory compliance, and autonomous AI agent data-product generation.

---

### 1.1 Specialized US Life, Annuity & Institutional Retirement Architectural Pillars

Unlike simplified retail-only insurance schemas, this enterprise data model must incorporate four real-world architectural capabilities used by leading US Life, Annuity, and Institutional Retirement carriers:

1. **Dual Contract Hierarchy (Employer-Sponsored Institutional Retirement Plans vs. Direct Retail Contracts)**
   - Contracts (`Policy`) can be issued either as **Direct Retail Policies** (Individual Term Life, Whole Life, Universal Life, Indexed Universal Life, Variable Universal Life, Traditional/Roth IRA Annuities, Multi-Year Guaranteed Annuities [MYGAs], Fixed Indexed Annuities [FIAs], Registered Index-Linked Annuities [RILAs], and Non-Qualified Deferred or Immediate Annuities) OR as **Institutional Retirement Plan Certificates / Individual Contracts** issued under an employer-sponsored workplace retirement plan (`403(b)`, `401(a)`, `401(k)`, `457(b)` Governmental, `457(b)` Tax-Exempt, and `457(f)` Non-Qualified Deferred Compensation).
   - When linked to an `Institutional Retirement Plan`, plan-level rules govern employee eligibility, pre-tax vs. Roth elective deferral limits (`IRC Section 402(g)`), employer matching and non-elective contributions (`IRC Section 415(c)`), multi-year vesting schedules (`Cliff` vs. `Graded`), plan loan limits (`IRC Section 72(p)`), and Qualified Default Investment Alternatives (`QDIA`).

2. **Participating General Account "Vintage Bucketing" Architecture**
   - Unlike simple fixed annuities that apply a single uniform crediting rate across an entire contract balance, participating General Account fixed annuities track contributions in **Crediting Rate Vintages (Buckets)** (`Policy Vintage Bucket Balance`).
   - Depending on the exact calendar window (*vintage*) in which a premium contribution, employer match, or internal transfer was received, that dollar tranche is assigned to a specific vintage bucket earning a contractual **Guaranteed Minimum Interest Rate** (e.g., `1.00%` to `3.00%`) plus vintage-specific **Additional Declared Dividend / Excess Interest** approved annually or periodically by the Board of Directors (`General Account Crediting Rate Declaration`).
   - Furthermore, General Account products enforce product-specific withdrawal and transfer liquidity regimes (`Product Crediting & Liquidity Rule`), including non-cashable lifetime-income-only retirement annuities (`RA`), 10-year staged *Transfer Payout Annuity (`TPA`)* annual installments (`120 months`) under Group Retirement Annuities (`GRA`), and `84-month` systematic withdrawal installments under institutional Retirement Choice (`RC`) contracts.

3. **Separate Account Dual-Unit Variable Accounting (`Accumulation Units` vs. `Annuity Payout Units`) & Direct Real Estate Accounts**
   - Variable Separate Account funds (`Investment Fund` & `Fund Unit Price`)—spanning equity sub-accounts, fixed-income sub-accounts, multi-asset target-date lifecycle series, and direct commercial real estate separate accounts (backed by a carrier general account liquidity guarantee)—operate on a **Dual-Unit Accounting System**:
     - **Accumulation Phase (`Accumulation Unit Value - AUV`)**: During the savings phase, incoming contributions purchase `Accumulation Units` at the daily 4:00 PM ET NYSE closing `Accumulation Unit Value (AUV)` (forward pricing under `SEC Rule 22c-1`), which fluctuates daily via the `Daily Net Investment Factor` net of fund management and Mortality & Expense (`M&E`) charges.
     - **Payout Phase (`Annuity Unit Value`)**: When a participant annuitizes variable savings into lifetime income, `Accumulation Units` convert into a fixed number of `Annuity Units`. Periodic variable income payments equal $\text{Annuity Units Held} \times \text{Annuity Unit Value}$, where `Annuity Unit Value` revalues periodically (monthly or annually) based on whether actual fund investment performance exceeded or trailed the hurdle **Assumed Investment Return (`AIR`)** rate (e.g., `4.00%`).

4. **Two-Phase Contract Lifecycle (Accumulation Phase $\rightarrow$ Lifetime Income / Annuitization Phase & Living Benefit Riders)**
   - The data model must seamlessly track both ways a deferred contract generates retirement income:
     - **Formal Annuitization (`Annuitization Payout Schedule`)**: Surrendering the liquid accumulation balance in exchange for an irrevocable or period-certain annuity payout contract (`Single Life`, `Life with 10/15/20-Year Period Certain`, `Joint and 50%/66.7%/75%/100% Survivor`, or `Fixed Period Installments`), shifting balance-sheet value from liquid `Current Total Contract Value` to `Actuarial Valuation Reserve`.
     - **Guaranteed Living & Death Benefit Riders (`Policy Rider Coverage` & `Rider Benefit Base Valuation`)**: Maintaining a protected shadow `Guaranteed Benefit Base Amount` (`GMWB` / `GLWB`, `GMIB`, `GMAB`, `GMDB`) with compound/simple roll-ups and high-water-mark anniversary step-ups while the policy remains active in accumulation (`Active in Accumulation`).

---

## 2. Comprehensive Scope: All 16 Enterprise L&A Data Domains

The enterprise data model is organized across **16 Core Domains**—combining the **10 Foundational Insurance Domains** with **6 Expanded Enterprise Operational & Regulatory Domains** required for end-to-end carrier operations:

### 2.1 Initial 10 Foundational Domains
1. **Domain 1 — `Product`**: Defines the master catalog of marketable Life Insurance and Annuity offerings (`Product Line`, `Product`), state-by-state SERFF/IIPRC regulatory filings (`Product State Filing & Availability`), general account crediting rate floors and staged withdrawal liquidity rules (`Product Crediting & Liquidity Rule`), eligible fund lineups (`Product Eligible Investment Fund`), and eligible riders (`Product Eligible Rider`).
2. **Domain 2 — `Policy` (Contract & Certificate Administration)**: Represents the central system of record for individual policies and institutional group certificates (`Policy`), layered life and annuity benefit segments (`Policy Coverage Segment`), participating general account contribution vintages (`Policy Vintage Bucket Balance`), and collateralized policy/plan loans (`Policy Loan`).
3. **Domain 3 — `Riders` (Supplemental Benefits & Living/Death Guarantees)**: Governs the catalog of optional and embedded riders (`Rider Product Definition` covering `GLWB`/`GMWB`, `GMIB`, `GMDB`, `Waiver of Premium`, `Chronic/Terminal Illness Accelerated Death Benefit`, and `COLA`), policy-level attachments (`Policy Rider Coverage`), and periodic shadow-account valuations (`Rider Benefit Base Valuation`).
4. **Domain 4 — `Fund` (General Account Vintages & Separate Account Sub-Accounts)**: Models underlying investment funds and indexed strategies (`Investment Fund`), daily accumulation and payout unit valuations (`Fund Unit Price`), policyholder allocation instructions (`Policy Fund Allocation Election`), and contract-level sub-account/vintage holdings (`Policy Valuation Account`).
5. **Domain 5 — `Transactions` (Policy Financial & Non-Financial Activity)**: Captures atomic financial money movements (`Financial Transaction` across contributions, rollovers, 1035 exchanges, transfers, surrenders, loan activity, fee deductions, and payouts), fund-level unit purchases/redemptions (`Transaction Fund Allocation Detail`), and administrative contract endorsements (`Non-Financial Service Transaction`).
6. **Domain 6 — `Reinsurance` (Ceded & Assumed Risk Management)**: Tracks external and affiliated reinsurers (`Reinsurer Counterparty`), mortality/longevity/coinsurance treaties (`Reinsurance Treaty` across `YRT`, `Coinsurance`, `ModCo`, `Funds Withheld`, and `Longevity Swaps`), policy-level risk cessions (`Reinsured Policy Cession`), and claim recoveries (`Reinsurance Claim Recovery`).
7. **Domain 7 — `Finance` (Insurance Sub-Ledger, General Ledger & Crediting Declarations)**: Bridges policy events and reserve movements into multi-basis (`US GAAP`, `Statutory NAIC`, `US Tax`) accounting via `General Ledger Account`, `Accounting Period`, `Sub-Ledger Journal Entry`, `Journal Entry Line`, and Board-approved `General Account Crediting Rate Declaration`.
8. **Domain 8 — `Experience Studies` (Historical Behavioral & Biometric Analytics)**: Tracks longitudinal biometric and policyholder behavior studies (`Experience Study` covering mortality, annuitant longevity, voluntary lapse/surrender, annuitization election, and GLWB utilization) and stratified Actual-to-Expected (`A/E`) cohorts (`Experience Exposure & Decrement Cohort`).
9. **Domain 9 — `Actuarial` (Valuation, Reserves, Pricing & Capital Modeling)**: Governs locked-in and best-estimate actuarial assumption tables (`Actuarial Assumption Set`), GAAP ASC 944 Long-Duration Targeted Improvements issue-year cohorts (`LDTI Valuation Cohort`), policy/model-point statutory (`VM-20`, `VM-21`, `VM-22`) and GAAP reserves plus Risk-Based Capital (`Actuarial Valuation Reserve`), and multi-scenario ALM projections (`Actuarial Cash Flow Projection`).
10. **Domain 10 — `Agent & Agency` (Distribution, Wealth Management & Compensation)**: Models internal wealth advisory channels, independent broker-dealers, IMOs, and banks (`Agency`), individual advisors and relationship managers (`Producer / Advisor`), state insurance licenses, carrier appointments, and FINRA/Reg BI credentials (`Producer License & Carrier Appointment`), policy split hierarchies (`Policy Producer Assignment`), and upfront/trail/chargeback commission statements (`Compensation Schedule & Commission Statement`).

### 2.2 Six Expanded Enterprise Domains (Completing the L&A Value Chain)
11. **Domain 11 — `Party, Customer & Household`**: Centralizes Master Data Management (`MDM`) for natural persons, trusts, estates, charities, and corporate entities (`Party`), verified physical/electronic addresses (`Party Contact & Address Profile`), household wealth aggregation (`Household`), and many-to-many contract participation roles (`Policy Party Role` for `Policy Owner`, `Joint Owner`, `Plan Participant`, `Primary Insured`, `Primary Annuitant`, `Primary Beneficiary`, `Contingent Beneficiary`, `Payor`, `Trustee`, and `Power of Attorney`) so a single person is never duplicated across multiple policies, workplace plans, and claims.
12. **Domain 12 — `Institutional Plan & Employer Sponsor`**: Captures institutional B2B2C retirement plan sponsors (`Employer Sponsor Organization` across universities, hospitals, K-12 districts, research institutes, and municipalities), workplace retirement plans (`Institutional Retirement Plan` for `403(b)`, `401(a)`, `401(k)`, and `457(b)/(f)`), employee class contribution/matching formulas (`Plan Eligibility & Contribution Rule`), and statutory vesting schedules (`Plan Vesting Schedule`).
13. **Domain 13 — `Underwriting & New Business`**: Separates pre-issue origination and mortality selection from in-force administration—covering pre-sale NAIC/AG 49-A illustrations (`Quote & Policy Illustration`), digital/paper order intake (`Application`), guaranteed-issue vs. accelerated algorithmic vs. full medical risk adjudication (`Underwriting Case & Risk Decision`), and third-party medical/Rx/MIB/APS evidence (`Medical & Mortality Requirement`).
14. **Domain 14 — `Claims, Annuitization & Benefit Payouts`**: Separates benefit settlement and retirement income distribution from everyday policy servicing—managing lifetime and period-certain income streams (`Annuitization Payout Schedule`), SECURE 1.0/2.0 Required Minimum Distributions (`Required Minimum Distribution Schedule`), death and living benefit claim adjudication (`Claim & Benefit Settlement`), and per-beneficiary settlement elections (`Beneficiary Claim Payout Election`).
15. **Domain 15 — `Billing, Remittance & Tax Reporting`**: Tracks institutional employer payroll wire/file reconciliation (`Institutional Payroll Remittance Batch` for pre-tax, Roth, employer match, and loan repayments), individual modal billing and IRS `W-4P`/`W-4R`/`W-8BEN` tax withholding elections (`Billing & Tax Withholding Schedule`), and annual IRS tax reporting (`Tax Reporting Statement` for Forms `1099-R`, `5498`, `1099-INT`, and `1042-S`).
16. **Domain 16 — `Compliance, Suitability & Regulatory Governance`**: Enforces pre-issue and post-issue regulatory controls—tracking `SEC Reg BI`, `NAIC Model #275`, `DOL PTE 2020-02`, and `NY Reg 187` reviews (`Suitability & Best Interest Review`), statutory delivery and right-to-cancel windows (`Free-Look & Rescission Tracking`), and Social Security Death Master File (`DMF`) cross-matching and state dormancy escheatment (`Unclaimed Property & Escheatment Case`).

---

## 3. Elaborate Step-by-Step Execution Workflow (Steps 1 through 4)

### Step 1: Design & Generate the Conceptual Data Model
* **Target Artifact**: `Output/L&A Data Model - Conceptual.MD`
* **Objective**: Establish the high-level executive and business architecture across all 16 domains before introducing physical column types or database syntax.
* **Detailed Instructions**:
  1. **Architectural Insights Overview**: Document the four core L&A architectural pillars (Dual Institutional/Retail Contract Hierarchy, General Account Vintage Bucketing, Separate Account Dual-Unit Accounting, and Accumulation-to-Payout Lifecycle).
  2. **16-Domain Executive Summary**: Define the scope and purpose of all 16 enterprise domains (`Domains 1–16`).
  3. **Cross-Domain Mermaid Entity-Relationship Diagram (`erDiagram`)**:
     - Construct a comprehensive Mermaid `erDiagram` connecting the core entities across all 16 domains using proper crow's-foot cardinality (`||--|{`, `||--o{`, `}o--||`, `||--||`, `||--o|`).
     - **Strict Naming Rule**: Every entity in the Mermaid diagram must use **100% business-friendly Title Case names enclosed in double quotes** (e.g., `"Policy"`, `"Product"`, `"Investment Fund"`, `"Institutional Retirement Plan"`, `"Annuitization Payout Schedule"`). Never use `UPPER_SNAKE_CASE` or abbreviated physical table names in the Conceptual Diagram.
  4. **Domain-by-Domain Conceptual Breakdown**:
     - For each of the 16 domains, list its conceptual entities (65 entities total across the enterprise).
     - Under each conceptual entity, list its core business-friendly attributes in backticks (e.g., `Policy Number`, `Current Total Contract Value`, `Guaranteed Minimum Interest Rate`) with representative business domain values in parentheses.
     - Explicitly document the $1:1$, $1:M$, and resolved $M:N$ conceptual relationships at the bottom of each domain section.

---

### Step 2: Design & Generate the Logical Data Model
* **Target Artifact**: `Output/L&A Data Model - Logical.MD`
* **Objective**: Expand the Conceptual Data Model into a rigorous, fully normalized (3NF) **Logical Data Model** across all 16 domains, 65 entities, and 560+ attributes using two standardized tabular catalogs.
* **Detailed Instructions**:
  1. **Section 1 — Logical Entity Catalog Table**:
     - Create a Markdown table with the exact three columns:
       `Domain Name` | `Entity Name` | `Entity Definitions`
     - Include all **65 Logical Entities** across all 16 domains.
     - Write a clear, comprehensive business definition ($\ge 100$ characters) for every entity explaining its functional role, business grain, and lifecycle significance.
  2. **Section 2 — Logical Attribute Catalog Table (Organized by Domain 1 through Domain 16)**:
     - Create Markdown tables for each of the 16 domains with the exact seven columns:
       `Domain Name` | `Entity Name` | `Attribute Name` | `Attribute Definitions` | `Data Type` | `Key` | `Column Order`
     - **Attribute Naming**: Every `Attribute Name` must be 100% business-friendly Title Case (e.g., `Policy Identifier`, `Contract Issue Date`, `Current Cash Surrender Value`).
     - **Attribute Definitions & Sample Values**: Every single `Attribute Definitions` cell **must be at least 50 characters long** (targeting 110–250 characters) and **must include concrete `Sample values:`** illustrating realistic US Life & Annuity domain values (e.g., `Sample values: PROD-GA-RA-01, PROD-CREF-VA-02, PROD-FIA-05, PROD-IUL-10`).
     - **Logical Data Types**: Use standardized logical data types (`String`, `Decimal`, `Integer`, `Date`, `Timestamp`, `Boolean`).
     - **Key Classification (`PK`, `FK`, `NK`)**:
       - `PK`: Surrogate or natural Primary Key uniquely identifying each row in the entity (always `Column Order = 1`).
       - `FK`: Foreign Key referencing the `PK` of a parent entity across the same or another domain.
       - `NK`: Non-Key business, financial, regulatory, or descriptive attribute.
     - **Column Order**: Number attributes sequentially (`1, 2, 3, ...`) within each entity starting at `1` for the Primary Key, followed by Foreign Keys, natural identifiers, and business attributes.

---

### Step 3: Design & Generate the Physical Database DDL (Amazon RDS Aurora PostgreSQL)
* **Target Artifact**: `Output/L&A Data Model - Physical DDL.sql`
* **Objective**: Translate the 65 entities and 560+ attributes of `Output/L&A Data Model - Logical.MD` into a clean, idempotent, production-ready **Amazon RDS Aurora PostgreSQL** (PostgreSQL 15/16 compatible) Data Definition Language (`DDL`) script.
* **Detailed Instructions**:
  1. **16 Domain Schemas**:
     - Create 16 dedicated PostgreSQL schemas (`CREATE SCHEMA IF NOT EXISTS <schema_name>;`) with `COMMENT ON SCHEMA` documentation:
       `product`, `policy`, `riders`, `fund`, `transactions`, `reinsurance`, `finance`, `experience_studies`, `actuarial`, `agent_and_agency`, `party_customer_and_household`, `institutional_plan_and_employer_sponsor`, `underwriting_and_new_business`, `claims_annuitization_and_benefit_payouts`, `billing_remittance_and_tax_reporting`, and `compliance_suitability_and_regulatory_governance`.
  2. **65 Physical Tables & Column Precision Mapping**:
     - Convert all 65 Logical Entity names and 560+ Logical Attribute names into standardized PostgreSQL `snake_case` identifiers while preserving the exact `Column Order` from the Logical Data Model.
     - Apply financial-grade PostgreSQL physical data types:
       - Primary & Foreign Key Identifiers: `VARCHAR(64)`
       - Business Codes, Tickers, Form Numbers & Short Statuses: `VARCHAR(30)` to `VARCHAR(100)`
       - Names, Descriptions & Regulatory Titles: `VARCHAR(255)` to `TEXT`
       - Monetary / Currency Amounts: `NUMERIC(18, 2)`
       - Unit Prices (`AUV` / `Annuity Unit Value`), Unit Counts, Interest/Crediting Rates, Mortality/A-E Ratios & Split Percentages: `NUMERIC(18, 6)` or `NUMERIC(10, 6)`
       - Counts, Durations, Issue Ages & Sequence Numbers: `INTEGER`
       - Calendar Dates: `DATE`
       - Audit Timestamps: `TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP` (`created_at_ts`, `updated_at_ts`)
  3. **Declarative Integrity Constraints & Indexing**:
     - **Primary Keys**: Explicit `CONSTRAINT pk_<table_name> PRIMARY KEY (<pk_column>)` on all 65 tables.
     - **Unique & Check Constraints**: Natural key `UNIQUE` constraints (e.g., `policy_number`, `product_code`, `treaty_number`) and domain-enforcing `CHECK` constraints (e.g., age bounds `minimum_issue_age >= 0 AND maximum_issue_age >= minimum_issue_age`, allocation percentages between `0` and `100`, non-negative reserve and face amounts).
     - **Cross-Schema Foreign Keys**: Add `ALTER TABLE ... ADD CONSTRAINT fk_... FOREIGN KEY (...) REFERENCES <parent_schema>.<parent_table>(<pk>) ON DELETE RESTRICT;` after table creation to guarantee clean dependency resolution across all 16 schemas.
     - **Performance Indexes**: Create B-Tree and composite indexes (`CREATE INDEX idx_...`) on all Foreign Keys, `policy_status`, `effective_date`, `valuation_date`, `tax_year`, and natural lookup keys.
     - **Catalog Metadata**: Include `COMMENT ON TABLE` for every table so database catalogs and AI SQL agents can introspect schema semantics directly from `pg_catalog`.

---

### Step 4: Author the Enterprise Business Ontology for AI Agent Training
* **Target Artifact**: `Output/L&A - Ontology.MD`
* **Objective**: Create an exhaustive semantic knowledge base and business rulebook designed to train autonomous AI agents to understand the deep domain relationships, actuarial/accounting formulas, regulatory constraints, and SQL query patterns required to build accurate data products out of the Logical and Physical Data Models.
* **Detailed Instructions**:
  1. **Section 1 — Comprehensive Data Domain Ontology Definitions (All 16 Domains)**:
     - Write an elaborate multi-paragraph ontology narrative (400–500 words per domain) for each of the **16 Enterprise Domains**.
     - Each domain definition must explain the business purpose of the domain, how its entities and key attributes interact, how data flows into and out of neighboring domains, and how AI agents should use the domain when constructing analytical or operational data products.
  2. **Section 2 — 300+ Elaborate Business Context Ontology Rules (`BC-001` through `BC-305`)**:
     - Author at least **300 distinct Business Contexts** (`305` contexts delivered: `BC-001` through `BC-305`), organized systematically across all 16 domains plus cross-domain enterprise synthesis guardrails.
     - **Mandatory Header Metadata per Business Context**:
       - `#### BC-XXX: <Descriptive Business Context Title>`
       - `**Domains**: <Participating Domains> | **Entities**: <Participating Logical Entities> | **Key Attributes**: <Participating Logical Attributes>`
     - **Minimum Word Count Requirement ($\ge 250$ Words per Business Context)**:
       - Every single Business Context (`BC-001` through `BC-305`) **must contain at least 250 words** (targeting 265–325 words per rule) of rich, business-friendly explanation.
     - **Mandatory Core Contract Invariants (Must Be Explicitly Modeled in `Domain 2: Policy`)**:
       - **Single Product per Policy (`BC-021`)**: A `Policy` is always instantiated under one and only one base `Product` (`1:M` from `Product` to `Policy`), while layered benefit tiers within that policy are represented via `Policy Coverage Segment`.
       - **Zero, One, or Multiple Riders per Policy (`BC-022`)**: A `Policy` can have zero, one, or multiple supplemental riders (`Policy Rider Coverage`) active at the same time (e.g., combining a `GLWB` living benefit rider with a `GMDB` death benefit rider, or combining `Waiver of Premium` with `Accelerated Death Benefit`), subject to `Product Eligible Rider` compatibility and category mutual-exclusivity rules.
       - **Inactive Policy Zero-Value Invariant (`BC-023`)**: Whenever `Policy Status` is in a terminal inactive state (`Surrendered`, `Lapsed`, `Death Claim Settled`, `Terminated - Free Look Cancelled`, `Terminated - Escheated`), its liquid `Current Total Contract Value` and `Current Cash Surrender Value` must equal `$0.00`. Explain the critical distinction for `Paid-Up` policies (which retain positive cash value with zero future billing) and `Active in Payout / Annuitized` policies (whose liquid accumulation value converts to `$0.00` while economic value shifts to `Annuitization Payout Schedule` and `Actuarial Valuation Reserve`).
       - **Mandatory Primary Policyholder & Dual Agent Assignment (`BC-024`)**: Every active `Policy` must always have a designated Primary Policyholder (`Policy Owner` / `Plan Participant` in `Policy Party Role`), a historical `Writing / Producing Agent` (`Policy Producer Assignment`), and a currently active `Servicing Advisor / Agent` (reassigned immediately upon advisor departure/termination so no active policy is ever left unserviced).
     - **Deep US Life & Annuity Regulatory, Actuarial & Tax Coverage Across All 16 Domains**:
       - Cover `IRC Sections 72, 101(a), 101(g), 401(a), 401(a)(9), 402(g), 403(b), 415(c), 457(b)/(f), 1035, 7702, 7702A (MEC 7-Pay Test), and 7702B`, `SECURE Act 1.0 & 2.0` RMD ages (`70.5`, `72`, `73`, `75`) and 10-year inherited beneficiary rules, `NAIC VM-20 / VM-21 / VM-22` Principles-Based Reserving, `US GAAP ASC 944 LDTI` cohorts and `Market Risk Benefits (MRB)`, `SEC Rule 22c-1` forward pricing, `SEC Reg BI / FINRA Rule 2330 / NAIC Model #275 / NY Reg 187 / DOL PTE 2020-02` suitability, `Forms W-4P / W-4R / W-8BEN`, `Forms 1099-R / 5498 / 1099-INT / 1042-S`, two-year contestability, `SSA Death Master File (DMF)` cross-matching, and multi-join SQL fan-out prevention ("Chasm Trap" guardrails).

---

## 4. Strict Guardrails & Quality Verification Standards

Every step and generated artifact in this workspace must strictly comply with the following non-negotiable guardrails:

1. **Conceptual First Sequencing**: Always establish and validate the **Conceptual Data Model** (`Output/L&A Data Model - Conceptual.MD`) first before generating the **Logical Data Model** (`Output/L&A Data Model - Logical.MD`), **Physical DDL** (`Output/L&A Data Model - Physical DDL.sql`), and **Business Ontology** (`Output/L&A - Ontology.MD`).
2. **100% Business-Friendly Naming in Conceptual, Logical & Ontology Artifacts**:
   - All Entity Names in the Conceptual Model (including the Mermaid `erDiagram`), Logical Model, and Business Ontology must use clear, business-friendly Title Case names (e.g., `Policy`, `Product`, `Policy Coverage Segment`, `Policy Vintage Bucket Balance`, `Annuitization Payout Schedule`).
   - All Attribute Names in the Conceptual, Logical, and Ontology documents must use clear, business-friendly Title Case names (e.g., `Policy Number`, `Contract Issue Date`, `Current Total Contract Value`, `Guaranteed Minimum Interest Rate`). Physical `snake_case` names are restricted exclusively to `Output/L&A Data Model - Physical DDL.sql`.
3. **Zero Vendor-Specific Carrier Brand References Across All Deliverables**:
   - **Strict Prohibition**: Do **not** include any specific carrier brand references (whether in prose, headers, entity names, attribute descriptions, or sample codes) in the Conceptual Data Model, Logical Data Model, Physical DDL, Business Ontology, or this Playbook.
   - Instead, express all institutional retirement, participating general account vintage bucketing (`PROD-GA-RA-01`, `GA-RA`, `GA-GRA`, `GA-RC`, `FUND-GA-TRAD`), real estate separate account (`FUND-SA-REA`), Transfer Payout Annuity (`TPA`), and lifetime income capabilities using **vendor-neutral enterprise US Life & Annuity terminology**.
4. **Completeness & No Truncation**:
   - Never use placeholders (such as `...`, `TBD`, or `/* remaining tables omitted */`). Every domain, entity, attribute, DDL table, and business context rule must be written out in full.
5. **Minimum Length & Depth Thresholds**:
   - **Logical Attribute Definitions**: Every attribute definition in `Output/L&A Data Model - Logical.MD` must be $\ge 50$ characters and include concrete `Sample values:`.
   - **Ontology Volume & Word Count**: `Output/L&A - Ontology.MD` must contain definitions for all **16 Domains** and at least **300 Business Contexts** (`305` delivered), and **every single Business Context (`BC-001` to `BC-305`) must be $\ge 250$ words** in body length.
