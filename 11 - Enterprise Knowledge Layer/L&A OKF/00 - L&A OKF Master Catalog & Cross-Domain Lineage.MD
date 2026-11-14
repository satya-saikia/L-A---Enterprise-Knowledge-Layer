# L&A Ontology Knowledge Framework (OKF) — Master Catalog & Cross-Domain Relational Lineage

| OKF Master Catalog Attribute | Value |
| :--- | :--- |
| **OKF Master Index Document** | `L&A OKF/00 - L&A OKF Master Catalog & Cross-Domain Lineage.MD` |
| **Target Database Platform** | Amazon RDS Aurora PostgreSQL (PostgreSQL 15/16 Compatible) |
| **Enterprise Data Domains** | **16 Core Domains / Physical Database Schemas** |
| **Total Logical Entities / Physical Tables** | **65 Tables** |
| **Total Physical Columns Harvested** | **722 Columns** (`592` Business Attributes + `130` Audit Timestamps) |
| **Total Declarative Table Constraints** | **142 Constraints** (`65` Primary Keys + `39` Unique Constraints + `38` Check Constraints) |
| **Total Relational Foreign Key Joins** | **94 Foreign Key Constraints** (`41` Intra-Domain Joins + `53` Cross-Domain Joins) |
| **Total Performance Indexes** | **94 B-Tree & Composite Indexes** |
| **Total Inherited Business Context Rules** | **305 Business Contexts (`BC-001` through `BC-305`, $\ge 264$ words each)** |
| **Source Knowledge Layer Artifacts** | `L&A Data Domain/L&A - Ontology.MD`, `L&A Data Domain/L&A Data Model - Logical.MD`, `L&A Data Domain/L&A Data Model - Physical DDL.sql`, `L&A Data Domain/L&A Data Model - Conceptual.MD` |

---

## 1. Executive Summary of the L&A Ontology Knowledge Framework (OKF)

The **Life & Annuity (L&A) Ontology Knowledge Framework (`OKF`)** is the authoritative enterprise data wiki and AI-agent semantic catalog bridging high-level business ontology (`L&A - Ontology.MD`) with low-level physical database implementation (`L&A Data Model - Physical DDL.sql`).

Every Domain OKF document (`01` through `16`) unites six layers of metadata in one place:
1. **Domain Executive Ontology Narrative**: The business, actuarial, accounting, and regulatory foundation of the domain.
2. **Physical Schema & Logical Entity Catalog**: Complete inventory of tables, primary keys, column counts, and table definitions.
3. **Relational Join Mining & Foreign Key Topology**: Visual Mermaid `erDiagram` and exact SQL join predicates for all outbound and inbound foreign keys.
4. **Attribute-to-Column Dictionary & DDL Constraints**: Every logical attribute mapped 1-to-1 to its physical PostgreSQL column name, data type, nullability/default modifier, sample values, `CHECK`/`UNIQUE` constraints, and B-Tree indexes.
5. **Inherited Business Context Ontology Rules (`BC-001` to `BC-305`)**: All 305 deep domain rules, mathematical formulas, and regulatory guardrails inherited directly from `L&A - Ontology.MD`.
6. **Canonical AI Agent SQL Query Patterns**: Verified SQL join templates preventing multi-join fan-out ("Chasm Trap") and point-in-time snapshot leakage.

---

## 2. Master Directory of All 16 Domain OKF Wiki Catalogs

| Domain # | OKF Wiki Document | Enterprise Data Domain Name | Physical PostgreSQL Schema | Tables | Business Cols | Total Cols | Outbound FKs | Inbound FKs | Indexes | Business Contexts (`BC-XXX`) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **01** | [`01 - OKF - Product.MD`](./01%20-%20OKF%20-%20Product.MD) | **Product** | `product` | 6 | 47 | 59 | 7 | 6 | 6 | `BC-001` – `BC-020` (20) |
| **02** | [`02 - OKF - Policy.MD`](./02%20-%20OKF%20-%20Policy.MD) | **Policy** | `policy` | 4 | 42 | 50 | 7 | 19 | 8 | `BC-021` – `BC-042` (22) |
| **03** | [`03 - OKF - Riders.MD`](./03%20-%20OKF%20-%20Riders.MD) | **Riders** | `riders` | 3 | 29 | 35 | 3 | 1 | 3 | `BC-043` – `BC-061` (19) |
| **04** | [`04 - OKF - Fund.MD`](./04%20-%20OKF%20-%20Fund.MD) | **Fund** | `fund` | 4 | 34 | 42 | 6 | 5 | 6 | `BC-062` – `BC-081` (20) |
| **05** | [`05 - OKF - Transactions.MD`](./05%20-%20OKF%20-%20Transactions.MD) | **Transactions** | `transactions` | 3 | 34 | 40 | 6 | 2 | 7 | `BC-082` – `BC-103` (22) |
| **06** | [`06 - OKF - Reinsurance.MD`](./06%20-%20OKF%20-%20Reinsurance.MD) | **Reinsurance** | `reinsurance` | 5 | 41 | 51 | 6 | 0 | 6 | `BC-104` – `BC-120` (17) |
| **07** | [`07 - OKF - Finance.MD`](./07%20-%20OKF%20-%20Finance.MD) | **Finance** | `finance` | 5 | 45 | 55 | 7 | 1 | 7 | `BC-121` – `BC-140` (20) |
| **08** | [`08 - OKF - Experience Studies.MD`](./08%20-%20OKF%20-%20Experience%20Studies.MD) | **Experience Studies** | `experience_studies` | 3 | 32 | 38 | 4 | 1 | 3 | `BC-141` – `BC-158` (18) |
| **09** | [`09 - OKF - Actuarial.MD`](./09%20-%20OKF%20-%20Actuarial.MD) | **Actuarial** | `actuarial` | 4 | 47 | 55 | 6 | 2 | 6 | `BC-159` – `BC-178` (20) |
| **10** | [`10 - OKF - Agent and Agency.MD`](./10%20-%20OKF%20-%20Agent%20and%20Agency.MD) | **Agent & Agency** | `agent_and_agency` | 5 | 44 | 54 | 7 | 2 | 7 | `BC-179` – `BC-198` (20) |
| **11** | [`11 - OKF - Party Customer and Household.MD`](./11%20-%20OKF%20-%20Party%20Customer%20and%20Household.MD) | **Party, Customer & Household** | `party_customer_and_household` | 5 | 47 | 57 | 6 | 9 | 7 | `BC-199` – `BC-218` (20) |
| **12** | [`12 - OKF - Institutional Plan and Employer Sponsor.MD`](./12%20-%20OKF%20-%20Institutional%20Plan%20and%20Employer%20Sponsor.MD) | **Institutional Plan & Employer Sponsor** | `institutional_plan_and_employer_sponsor` | 4 | 39 | 47 | 5 | 2 | 5 | `BC-219` – `BC-236` (18) |
| **13** | [`13 - OKF - Underwriting and New Business.MD`](./13%20-%20OKF%20-%20Underwriting%20and%20New%20Business.MD) | **Underwriting & New Business** | `underwriting_and_new_business` | 4 | 37 | 45 | 8 | 2 | 6 | `BC-237` – `BC-254` (18) |
| **14** | [`14 - OKF - Claims Annuitization and Benefit Payouts.MD`](./14%20-%20OKF%20-%20Claims%20Annuitization%20and%20Benefit%20Payouts.MD) | **Claims, Annuitization & Benefit Payouts** | `claims_annuitization_and_benefit_payouts` | 4 | 42 | 50 | 8 | 2 | 7 | `BC-255` – `BC-272` (18) |
| **15** | [`15 - OKF - Billing Remittance and Tax Reporting.MD`](./15%20-%20OKF%20-%20Billing%20Remittance%20and%20Tax%20Reporting.MD) | **Billing, Remittance & Tax Reporting** | `billing_remittance_and_tax_reporting` | 3 | 34 | 40 | 4 | 1 | 5 | `BC-273` – `BC-289` (17) |
| **16** | [`16 - OKF - Compliance Suitability and Regulatory Governance.MD`](./16%20-%20OKF%20-%20Compliance%20Suitability%20and%20Regulatory%20Governance.MD) | **Compliance, Suitability & Regulatory Governance** | `compliance_suitability_and_regulatory_governance` | 3 | 32 | 38 | 4 | 0 | 5 | `BC-290` – `BC-305` (16) |
| **TOTAL** | **16 Domain OKF Documents + 1 Master Catalog** | **All 16 Enterprise L&A Domains** | **16 Schemas** | **65** | **592** | **722** | **94** | **55** | **94** | **`BC-001` – `BC-305` (305)** |

---

## 3. Enterprise Cross-Domain Relational Hub Topology

Across the 94 Foreign Key relationships in the physical database, five core master/hub entities anchor cross-domain joins:
1. **`policy.policy` (`policy_identifier`)**: The central operational contract hub of the enterprise, referenced by **19 inbound cross-domain and intra-domain Foreign Keys** across `policy_coverage_segment`, `policy_vintage_bucket_balance`, `policy_loan`, `riders.policy_rider_coverage`, `fund.policy_fund_allocation_election`, `fund.policy_valuation_account`, `transactions.financial_transaction`, `transactions.non_financial_service_transaction`, `reinsurance.reinsured_policy_cession`, `experience_studies.experience_study_policy_observation`, `actuarial.actuarial_valuation_reserve`, `actuarial.actuarial_cash_flow_projection`, `agent_and_agency.policy_producer_assignment`, `party_customer_and_household.policy_party_role`, `claims_annuitization_and_benefit_payouts.annuitization_payout_schedule`, `claims_annuitization_and_benefit_payouts.required_minimum_distribution_schedule`, `claims_annuitization_and_benefit_payouts.claim_and_benefit_settlement`, `billing_remittance_and_tax_reporting.billing_and_tax_withholding_schedule`, `billing_remittance_and_tax_reporting.tax_reporting_statement`, `compliance_suitability_and_regulatory_governance.free_look_and_rescission_tracking`, and `compliance_suitability_and_regulatory_governance.unclaimed_property_and_escheatment_case`.
2. **`party_customer_and_household.party` (`party_identifier`)**: The enterprise Customer & Party MDM hub, referenced by **12 Foreign Keys** across `party_contact_and_address_profile`, `household`, `household_member_assignment`, `policy_party_role`, `employer_sponsor_organization`, `application`, `underwriting_case_and_risk_decision`, `annuitization_payout_schedule` (primary & joint survivor annuitants), `claim_and_benefit_settlement`, `beneficiary_claim_payout_election`, and `tax_reporting_statement`.
3. **`product.product` (`product_identifier`)**: The master product blueprint hub, referenced by **8 Foreign Keys** across `product_state_filing_and_availability`, `product_crediting_and_liquidity_rule`, `product_eligible_investment_fund`, `product_eligible_rider`, `policy.policy`, `finance.general_account_crediting_rate_declaration`, `underwriting_and_new_business.quote_and_policy_illustration`, and `underwriting_and_new_business.application`.
4. **`fund.investment_fund` (`investment_fund_identifier`)**: The investment vehicle hub, referenced by **6 Foreign Keys** across `product.product_eligible_investment_fund`, `fund.fund_unit_price`, `fund.policy_fund_allocation_election`, `fund.policy_valuation_account`, `transactions.transaction_fund_allocation_detail`, and `institutional_plan_and_employer_sponsor.institutional_retirement_plan` (`QDIA`).
5. **`institutional_plan_and_employer_sponsor.institutional_retirement_plan` (`institutional_plan_identifier`)**: The B2B2C workplace retirement plan hub, referenced by **4 Foreign Keys** across `plan_eligibility_and_contribution_rule`, `plan_vesting_schedule`, `policy.policy`, and `billing_remittance_and_tax_reporting.institutional_payroll_remittance_batch`.
