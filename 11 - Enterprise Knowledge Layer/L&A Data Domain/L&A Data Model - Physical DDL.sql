-- ============================================================================
-- LIFE & ANNUITY (L&A) INSURANCE ORGANIZATION — PHYSICAL DATA MODEL DDL
-- Target Engine : Amazon RDS Aurora PostgreSQL (Compatible with PostgreSQL 15/16)
-- Source Model  : Output/L&A Data Model - Logical.MD (All 16 Domains, 65 Entities)
-- Architecture  : Enterprise US Life & Annuity (General Account Vintage
--                 Buckets, Variable Accumulation/Annuity Units, Institutional Plans,
--                 and Lifetime Income Payouts)
-- ============================================================================

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

-- ============================================================================
-- SECTION 1: SCHEMA DEFINITIONS (16 ENTERPRISE DATA DOMAINS)
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS product;
COMMENT ON SCHEMA product IS 'Domain 1: Product — Product lines, life & annuity products, state filings, crediting/liquidity rules, and eligible funds/riders.';

CREATE SCHEMA IF NOT EXISTS policy;
COMMENT ON SCHEMA policy IS 'Domain 2: Policy — Individual contracts, institutional group certificates, coverage segments, general account vintage buckets, and policy loans.';

CREATE SCHEMA IF NOT EXISTS riders;
COMMENT ON SCHEMA riders IS 'Domain 3: Riders — Supplemental benefit definitions (GMWB, GMIB, GMDB, Waiver), attached policy riders, and periodic benefit base valuations.';

CREATE SCHEMA IF NOT EXISTS fund;
COMMENT ON SCHEMA fund IS 'Domain 4: Fund — Separate account variable funds (CREF/Nuveen), general account fixed options, unit prices (AUV/Annuity Units), allocations, and holdings.';

CREATE SCHEMA IF NOT EXISTS transactions;
COMMENT ON SCHEMA transactions IS 'Domain 5: Transactions — Financial policy transactions, fund/vintage allocation line details, and non-financial administrative endorsements.';

CREATE SCHEMA IF NOT EXISTS reinsurance;
COMMENT ON SCHEMA reinsurance IS 'Domain 6: Reinsurance — Reinsurer counterparties, YRT/Coinsurance/ModCo treaties, syndicate participants, policy cessions, and claim recoveries.';

CREATE SCHEMA IF NOT EXISTS finance;
COMMENT ON SCHEMA finance IS 'Domain 7: Finance — Chart of accounts, accounting periods, insurance sub-ledger journal entries/lines, and general account crediting rate declarations.';

CREATE SCHEMA IF NOT EXISTS experience_studies;
COMMENT ON SCHEMA experience_studies IS 'Domain 8: Experience Studies — Historical mortality, longevity, lapse, annuitization, and rider utilization studies, cohorts, and policy observations.';

CREATE SCHEMA IF NOT EXISTS actuarial;
COMMENT ON SCHEMA actuarial IS 'Domain 9: Actuarial — Assumption sets, US GAAP LDTI cohorts, statutory/GAAP/tax valuation reserves (VM-20/21/22), and ALM cash flow projections.';

CREATE SCHEMA IF NOT EXISTS agent_and_agency;
COMMENT ON SCHEMA agent_and_agency IS 'Domain 10: Agent & Agency — Distribution partner agencies/broker-dealers, producers/advisors, state licenses/appointments, splits, and commissions.';

CREATE SCHEMA IF NOT EXISTS party_customer_and_household;
COMMENT ON SCHEMA party_customer_and_household IS 'Domain 11: Party, Customer & Household — Enterprise MDM parties, contact/address profiles, households, household members, and policy party roles.';

CREATE SCHEMA IF NOT EXISTS institutional_plan_and_employer_sponsor;
COMMENT ON SCHEMA institutional_plan_and_employer_sponsor IS 'Domain 12: Institutional Plan & Employer Sponsor — Employer sponsors, 403(b)/401(a)/457 plans, eligibility/matching rules, and vesting schedules.';

CREATE SCHEMA IF NOT EXISTS underwriting_and_new_business;
COMMENT ON SCHEMA underwriting_and_new_business IS 'Domain 13: Underwriting & New Business — Pre-sale illustrations/quotes, applications, underwriting risk decisions, and medical/mortality requirements.';

CREATE SCHEMA IF NOT EXISTS claims_annuitization_and_benefit_payouts;
COMMENT ON SCHEMA claims_annuitization_and_benefit_payouts IS 'Domain 14: Claims, Annuitization & Benefit Payouts — Lifetime annuitization schedules, RMD schedules, benefit claims, and beneficiary payout elections.';

CREATE SCHEMA IF NOT EXISTS billing_remittance_and_tax_reporting;
COMMENT ON SCHEMA billing_remittance_and_tax_reporting IS 'Domain 15: Billing, Remittance & Tax Reporting — Institutional payroll remittance batches, billing/withholding schedules, and IRS 1099-R/5498 statements.';

CREATE SCHEMA IF NOT EXISTS compliance_suitability_and_regulatory_governance;
COMMENT ON SCHEMA compliance_suitability_and_regulatory_governance IS 'Domain 16: Compliance, Suitability & Regulatory Governance — Reg BI / NAIC suitability reviews, free-look rescission tracking, and escheatment cases.';


-- ============================================================================
-- SECTION 2: DOMAIN 1 — PRODUCT (SCHEMA: product)
-- ============================================================================

-- 1.1 Product Line
CREATE TABLE IF NOT EXISTS product.product_line (
    product_line_identifier             VARCHAR(64)     NOT NULL,
    line_of_business_code               VARCHAR(32)     NOT NULL,
    product_line_name                   VARCHAR(150)    NOT NULL,
    regulatory_tax_qualification_type   VARCHAR(100)    NOT NULL,
    target_market_segment               VARCHAR(120)    NOT NULL,
    created_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_product_line PRIMARY KEY (product_line_identifier),
    CONSTRAINT uq_product_line_lob_code UNIQUE (line_of_business_code)
);
COMMENT ON TABLE product.product_line IS 'Product Line entity defines the high-level executive and regulatory categorization of Life and Annuity offerings marketed by the organization.';

-- 1.2 Product
CREATE TABLE IF NOT EXISTS product.product (
    product_identifier                      VARCHAR(64)     NOT NULL,
    product_line_identifier                 VARCHAR(64)     NOT NULL,
    product_code                            VARCHAR(32)     NOT NULL,
    product_name                            VARCHAR(200)    NOT NULL,
    product_category                        VARCHAR(100)    NOT NULL,
    general_or_separate_account_indicator   VARCHAR(64)     NOT NULL,
    issuing_legal_company_code              VARCHAR(32)     NOT NULL,
    effective_launch_date                   DATE            NOT NULL,
    closure_to_new_business_date            DATE            NULL,
    minimum_issue_age                       INTEGER         NOT NULL DEFAULT 0,
    maximum_issue_age                       INTEGER         NOT NULL DEFAULT 95,
    minimum_initial_contribution_amount     NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    surrender_charge_schedule_type          VARCHAR(150)    NOT NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_product PRIMARY KEY (product_identifier),
    CONSTRAINT uq_product_code UNIQUE (product_code),
    CONSTRAINT chk_product_issue_age CHECK (maximum_issue_age >= minimum_issue_age AND minimum_issue_age >= 0),
    CONSTRAINT chk_product_min_contrib CHECK (minimum_initial_contribution_amount >= 0)
);
COMMENT ON TABLE product.product IS 'Product entity holds the master catalog definition of each marketable Life Insurance or Annuity contract design.';

-- 1.3 Product State Filing & Availability
CREATE TABLE IF NOT EXISTS product.product_state_filing_and_availability (
    product_state_filing_identifier     VARCHAR(64)     NOT NULL,
    product_identifier                  VARCHAR(64)     NOT NULL,
    jurisdiction_state_name             VARCHAR(64)     NOT NULL,
    state_filing_approval_number        VARCHAR(100)    NOT NULL,
    approval_effective_date             DATE            NOT NULL,
    state_variation_form_number         VARCHAR(100)    NOT NULL,
    distribution_channel_eligibility    VARCHAR(150)    NOT NULL,
    created_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_product_state_filing PRIMARY KEY (product_state_filing_identifier),
    CONSTRAINT uq_product_state_jurisdiction UNIQUE (product_identifier, jurisdiction_state_name, state_variation_form_number)
);
COMMENT ON TABLE product.product_state_filing_and_availability IS 'Tracks regulatory submission, IIPRC or state DOI approval status, policy form numbers, and channel selling eligibility across US states.';

-- 1.4 Product Crediting & Liquidity Rule
CREATE TABLE IF NOT EXISTS product.product_crediting_and_liquidity_rule (
    crediting_and_liquidity_rule_identifier     VARCHAR(64)     NOT NULL,
    product_identifier                          VARCHAR(64)     NOT NULL,
    rule_name                                   VARCHAR(200)    NOT NULL,
    guaranteed_minimum_interest_rate            NUMERIC(9,6)    NOT NULL DEFAULT 0.010000,
    lump_sum_withdrawal_allowed_indicator       VARCHAR(100)    NOT NULL,
    required_installment_payout_period_months   INTEGER         NOT NULL DEFAULT 0,
    early_withdrawal_penalty_percentage         NUMERIC(9,6)    NOT NULL DEFAULT 0.000000,
    created_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_product_crediting_liquidity_rule PRIMARY KEY (crediting_and_liquidity_rule_identifier),
    CONSTRAINT chk_pclr_guar_rate CHECK (guaranteed_minimum_interest_rate >= 0),
    CONSTRAINT chk_pclr_installment_months CHECK (required_installment_payout_period_months >= 0),
    CONSTRAINT chk_pclr_penalty_pct CHECK (early_withdrawal_penalty_percentage >= 0 AND early_withdrawal_penalty_percentage <= 1)
);
COMMENT ON TABLE product.product_crediting_and_liquidity_rule IS 'Defines contractual interest rate floors, liquidity restrictions, and mandatory multi-year installment withdrawal rules (e.g., 10-yr TPA / 84-month RC).';

-- 1.5 Product Eligible Investment Fund (Associative Rule Entity)
CREATE TABLE IF NOT EXISTS product.product_eligible_investment_fund (
    product_eligible_fund_identifier    VARCHAR(64)     NOT NULL,
    product_identifier                  VARCHAR(64)     NOT NULL,
    investment_fund_identifier          VARCHAR(64)     NOT NULL,
    maximum_allocation_percentage       NUMERIC(9,6)    NOT NULL DEFAULT 1.000000,
    created_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_product_eligible_investment_fund PRIMARY KEY (product_eligible_fund_identifier),
    CONSTRAINT uq_product_eligible_fund UNIQUE (product_identifier, investment_fund_identifier),
    CONSTRAINT chk_pef_max_alloc_pct CHECK (maximum_allocation_percentage > 0 AND maximum_allocation_percentage <= 1)
);
COMMENT ON TABLE product.product_eligible_investment_fund IS 'Associative rule table linking Products to eligible Investment Funds approved under the prospectus or plan menu.';

-- 1.6 Product Eligible Rider (Associative Rule Entity)
CREATE TABLE IF NOT EXISTS product.product_eligible_rider (
    product_eligible_rider_identifier       VARCHAR(64)     NOT NULL,
    product_identifier                      VARCHAR(64)     NOT NULL,
    rider_product_identifier                VARCHAR(64)     NOT NULL,
    mandatory_embedded_vs_optional_election VARCHAR(100)    NOT NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_product_eligible_rider PRIMARY KEY (product_eligible_rider_identifier),
    CONSTRAINT uq_product_eligible_rider UNIQUE (product_identifier, rider_product_identifier)
);
COMMENT ON TABLE product.product_eligible_rider IS 'Associative rule table linking base Products to eligible Rider Product Definitions.';


-- ============================================================================
-- SECTION 3: DOMAIN 2 — POLICY (SCHEMA: policy)
-- ============================================================================

-- 2.1 Policy
CREATE TABLE IF NOT EXISTS policy.policy (
    policy_identifier                       VARCHAR(64)     NOT NULL,
    product_identifier                      VARCHAR(64)     NOT NULL,
    institutional_plan_identifier           VARCHAR(64)     NULL,
    application_identifier                  VARCHAR(64)     NULL,
    policy_number                           VARCHAR(64)     NOT NULL,
    contract_certificate_number             VARCHAR(64)     NULL,
    source_administration_system_code       VARCHAR(50)     NOT NULL,
    policy_status                           VARCHAR(64)     NOT NULL,
    contract_issue_date                     DATE            NOT NULL,
    issue_state                             VARCHAR(10)     NOT NULL,
    tax_qualification_status                VARCHAR(100)    NOT NULL,
    face_amount                             NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    current_total_contract_value            NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    current_cash_surrender_value            NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    cost_basis_amount                       NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    free_look_expiration_date               DATE            NULL,
    maturity_or_mandatory_annuitization_date DATE           NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_policy PRIMARY KEY (policy_identifier),
    CONSTRAINT uq_policy_number UNIQUE (policy_number),
    CONSTRAINT chk_policy_amounts CHECK (face_amount >= 0 AND current_total_contract_value >= 0 AND current_cash_surrender_value >= 0 AND cost_basis_amount >= 0)
);
COMMENT ON TABLE policy.policy IS 'Policy entity holds the core contract and certificate master information for all Life Insurance policies and Annuity contracts.';

-- 2.2 Policy Coverage Segment
CREATE TABLE IF NOT EXISTS policy.policy_coverage_segment (
    policy_coverage_segment_identifier  VARCHAR(64)     NOT NULL,
    policy_identifier                   VARCHAR(64)     NOT NULL,
    coverage_sequence_number            INTEGER         NOT NULL,
    coverage_type                       VARCHAR(100)    NOT NULL,
    coverage_effective_date             DATE            NOT NULL,
    coverage_benefit_amount             NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    mortality_risk_class                VARCHAR(100)    NOT NULL,
    premium_payment_mode                VARCHAR(100)    NOT NULL,
    created_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_policy_coverage_segment PRIMARY KEY (policy_coverage_segment_identifier),
    CONSTRAINT uq_policy_coverage_seq UNIQUE (policy_identifier, coverage_sequence_number),
    CONSTRAINT chk_coverage_seq_positive CHECK (coverage_sequence_number >= 1)
);
COMMENT ON TABLE policy.policy_coverage_segment IS 'Represents an individual benefit layer or coverage tranche within a Policy (base life coverage, supplemental term layer, paid-up additions).';

-- 2.3 Policy Vintage Bucket Balance (General Account Vintage Architecture)
CREATE TABLE IF NOT EXISTS policy.policy_vintage_bucket_balance (
    policy_vintage_bucket_identifier        VARCHAR(64)     NOT NULL,
    policy_identifier                       VARCHAR(64)     NOT NULL,
    crediting_rate_declaration_identifier   VARCHAR(64)     NULL,
    vintage_period_identifier               VARCHAR(64)     NOT NULL,
    contribution_start_date                 DATE            NOT NULL,
    contribution_end_date                   DATE            NOT NULL,
    guaranteed_minimum_interest_rate        NUMERIC(9,6)    NOT NULL,
    current_declared_total_crediting_rate   NUMERIC(9,6)    NOT NULL,
    vintage_accumulated_balance_amount      NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    restricted_liquidity_indicator          VARCHAR(120)    NOT NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_policy_vintage_bucket_balance PRIMARY KEY (policy_vintage_bucket_identifier),
    CONSTRAINT uq_policy_vintage_period UNIQUE (policy_identifier, vintage_period_identifier),
    CONSTRAINT chk_vintage_dates CHECK (contribution_end_date >= contribution_start_date),
    CONSTRAINT chk_vintage_rates CHECK (current_declared_total_crediting_rate >= guaranteed_minimum_interest_rate)
);
COMMENT ON TABLE policy.policy_vintage_bucket_balance IS 'Tracks general account contributions and balances grouped by calendar contribution vintage for vintage-bucketed interest crediting.';

-- 2.4 Policy Loan
CREATE TABLE IF NOT EXISTS policy.policy_loan (
    policy_loan_identifier          VARCHAR(64)     NOT NULL,
    policy_identifier               VARCHAR(64)     NOT NULL,
    loan_number                     VARCHAR(64)     NOT NULL,
    loan_issue_date                 DATE            NOT NULL,
    loan_type                       VARCHAR(120)    NOT NULL,
    original_loan_principal_amount  NUMERIC(18,2)   NOT NULL,
    outstanding_principal_balance   NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    accrued_loan_interest_amount    NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    loan_interest_rate              NUMERIC(9,6)    NOT NULL,
    loan_default_status             VARCHAR(100)    NOT NULL,
    created_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_policy_loan PRIMARY KEY (policy_loan_identifier),
    CONSTRAINT uq_policy_loan_number UNIQUE (loan_number),
    CONSTRAINT chk_loan_amounts CHECK (original_loan_principal_amount > 0 AND outstanding_principal_balance >= 0 AND accrued_loan_interest_amount >= 0)
);
COMMENT ON TABLE policy.policy_loan IS 'Records collateralized loans taken by a policyholder or retirement plan participant against cash surrender value or vested plan accumulation.';


-- ============================================================================
-- SECTION 4: DOMAIN 3 — RIDERS (SCHEMA: riders)
-- ============================================================================

-- 3.1 Rider Product Definition
CREATE TABLE IF NOT EXISTS riders.rider_product_definition (
    rider_product_identifier        VARCHAR(64)     NOT NULL,
    rider_code                      VARCHAR(50)     NOT NULL,
    rider_name                      VARCHAR(200)    NOT NULL,
    rider_category                  VARCHAR(120)    NOT NULL,
    optional_vs_embedded_indicator  VARCHAR(100)    NOT NULL,
    rider_fee_calculation_basis     VARCHAR(120)    NOT NULL,
    annual_step_up_rate             NUMERIC(9,6)    NOT NULL DEFAULT 0.000000,
    waiting_period_years            INTEGER         NOT NULL DEFAULT 0,
    created_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_rider_product_definition PRIMARY KEY (rider_product_identifier),
    CONSTRAINT uq_rider_code UNIQUE (rider_code),
    CONSTRAINT chk_rider_waiting_years CHECK (waiting_period_years >= 0)
);
COMMENT ON TABLE riders.rider_product_definition IS 'Catalogs optional and embedded supplemental benefit guarantees (GMWB, GMIB, GMDB, Waiver of Premium, LTC/Chronic Illness).';

-- 3.2 Policy Rider Coverage
CREATE TABLE IF NOT EXISTS riders.policy_rider_coverage (
    policy_rider_identifier         VARCHAR(64)     NOT NULL,
    policy_identifier               VARCHAR(64)     NOT NULL,
    rider_product_identifier        VARCHAR(64)     NOT NULL,
    rider_status                    VARCHAR(100)    NOT NULL,
    rider_effective_date            DATE            NOT NULL,
    rider_termination_date          DATE            NULL,
    current_annual_rider_charge_rate NUMERIC(9,6)   NOT NULL DEFAULT 0.000000,
    created_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_policy_rider_coverage PRIMARY KEY (policy_rider_identifier),
    CONSTRAINT chk_rider_dates CHECK (rider_termination_date IS NULL OR rider_termination_date >= rider_effective_date)
);
COMMENT ON TABLE riders.policy_rider_coverage IS 'Represents an active or historical instance of a supplemental Rider Product attached to a specific Policy.';

-- 3.3 Rider Benefit Base Valuation
CREATE TABLE IF NOT EXISTS riders.rider_benefit_base_valuation (
    rider_valuation_identifier                      VARCHAR(64)     NOT NULL,
    policy_rider_identifier                         VARCHAR(64)     NOT NULL,
    valuation_date                                  DATE            NOT NULL,
    guaranteed_benefit_base_amount                  NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    high_water_mark_value                           NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    roll_up_base_amount                             NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    maximum_annual_lifetime_withdrawal_percentage   NUMERIC(9,6)    NOT NULL DEFAULT 0.000000,
    remaining_guaranteed_annual_withdrawal_amount   NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    excess_withdrawal_reduction_amount              NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    created_at                                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_rider_benefit_base_valuation PRIMARY KEY (rider_valuation_identifier),
    CONSTRAINT uq_rider_valuation_date UNIQUE (policy_rider_identifier, valuation_date)
);
COMMENT ON TABLE riders.rider_benefit_base_valuation IS 'Records periodic point-in-time valuations of a policy rider guaranteed benefit base, high-water marks, roll-up bases, and withdrawal allowances.';


-- ============================================================================
-- SECTION 5: DOMAIN 4 — FUND (SCHEMA: fund)
-- ============================================================================

-- 4.1 Investment Fund
CREATE TABLE IF NOT EXISTS fund.investment_fund (
    investment_fund_identifier          VARCHAR(64)     NOT NULL,
    fund_ticker_or_code                 VARCHAR(32)     NOT NULL,
    fund_name                           VARCHAR(200)    NOT NULL,
    account_structure_type              VARCHAR(120)    NOT NULL,
    asset_class                         VARCHAR(120)    NOT NULL,
    fund_manager_name                   VARCHAR(150)    NOT NULL,
    net_expense_ratio_percentage        NUMERIC(9,6)    NOT NULL DEFAULT 0.000000,
    assumed_investment_return_rate_air  NUMERIC(9,6)    NULL,
    fund_inception_date                 DATE            NOT NULL,
    closed_to_new_investors_indicator   VARCHAR(100)    NOT NULL,
    created_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_investment_fund PRIMARY KEY (investment_fund_identifier),
    CONSTRAINT uq_investment_fund_ticker UNIQUE (fund_ticker_or_code)
);
COMMENT ON TABLE fund.investment_fund IS 'Defines each underlying investment vehicle available within Separate Account variable products (CREF, Nuveen), Indexed strategies, and General Account fixed options.';

-- 4.2 Fund Unit Price
CREATE TABLE IF NOT EXISTS fund.fund_unit_price (
    fund_unit_price_identifier      VARCHAR(64)     NOT NULL,
    investment_fund_identifier      VARCHAR(64)     NOT NULL,
    valuation_date                  DATE            NOT NULL,
    accumulation_unit_value_auv     NUMERIC(18,6)   NOT NULL,
    annuity_unit_value              NUMERIC(18,6)   NULL,
    daily_net_investment_factor     NUMERIC(18,8)   NOT NULL DEFAULT 1.00000000,
    total_fund_net_assets_amount    NUMERIC(20,2)   NOT NULL DEFAULT 0.00,
    created_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_fund_unit_price PRIMARY KEY (fund_unit_price_identifier),
    CONSTRAINT uq_fund_unit_price_date UNIQUE (investment_fund_identifier, valuation_date),
    CONSTRAINT chk_fund_auv_positive CHECK (accumulation_unit_value_auv > 0)
);
COMMENT ON TABLE fund.fund_unit_price IS 'Stores daily or periodic net asset valuations for each Investment Fund, including both Accumulation Unit Value (AUV) and Annuity Unit Value.';

-- 4.3 Policy Fund Allocation Election
CREATE TABLE IF NOT EXISTS fund.policy_fund_allocation_election (
    policy_allocation_election_identifier   VARCHAR(64)     NOT NULL,
    policy_identifier                       VARCHAR(64)     NOT NULL,
    investment_fund_identifier              VARCHAR(64)     NOT NULL,
    allocation_type                         VARCHAR(120)    NOT NULL,
    allocation_effective_date               DATE            NOT NULL,
    allocation_percentage                   NUMERIC(9,6)    NOT NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_policy_fund_allocation_election PRIMARY KEY (policy_allocation_election_identifier),
    CONSTRAINT chk_pfae_alloc_pct CHECK (allocation_percentage >= 0 AND allocation_percentage <= 1)
);
COMMENT ON TABLE fund.policy_fund_allocation_election IS 'Captures standing instructions for how future premium contributions, rebalancing, and DCA transfers are split across eligible Investment Funds.';

-- 4.4 Policy Valuation Account (Sub-Account Holding)
CREATE TABLE IF NOT EXISTS fund.policy_valuation_account (
    holding_account_identifier          VARCHAR(64)     NOT NULL,
    policy_identifier                   VARCHAR(64)     NOT NULL,
    investment_fund_identifier          VARCHAR(64)     NOT NULL,
    policy_vintage_bucket_identifier    VARCHAR(64)     NULL,
    valuation_phase                     VARCHAR(100)    NOT NULL,
    number_of_accumulation_units_held   NUMERIC(18,6)   NOT NULL DEFAULT 0.000000,
    number_of_annuity_units_held        NUMERIC(18,6)   NOT NULL DEFAULT 0.000000,
    current_market_value_amount         NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    surrender_free_value_amount         NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    created_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_policy_valuation_account PRIMARY KEY (holding_account_identifier),
    CONSTRAINT chk_pva_units_non_neg CHECK (number_of_accumulation_units_held >= 0 AND number_of_annuity_units_held >= 0)
);
COMMENT ON TABLE fund.policy_valuation_account IS 'Holds current sub-account position and unit balances for a specific Policy within a specific Investment Fund across accumulation and payout phases.';


-- ============================================================================
-- SECTION 6: DOMAIN 5 — TRANSACTIONS (SCHEMA: transactions)
-- ============================================================================

-- 5.1 Financial Transaction
CREATE TABLE IF NOT EXISTS transactions.financial_transaction (
    financial_transaction_identifier    VARCHAR(64)     NOT NULL,
    policy_identifier                   VARCHAR(64)     NOT NULL,
    remittance_batch_identifier         VARCHAR(64)     NULL,
    transaction_reference_number        VARCHAR(64)     NOT NULL,
    transaction_type                    VARCHAR(120)    NOT NULL,
    transaction_effective_date          DATE            NOT NULL,
    transaction_processing_date         DATE            NOT NULL,
    valuation_price_date                DATE            NOT NULL,
    gross_transaction_amount            NUMERIC(18,2)   NOT NULL,
    surrender_charge_deducted_amount    NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    market_value_adjustment_mva_amount  NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    federal_tax_withheld_amount         NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    state_tax_withheld_amount           NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    net_transaction_amount              NUMERIC(18,2)   NOT NULL,
    transaction_reversal_indicator      VARCHAR(64)     NOT NULL DEFAULT 'Active Original Posting',
    created_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_financial_transaction PRIMARY KEY (financial_transaction_identifier),
    CONSTRAINT uq_financial_transaction_ref UNIQUE (transaction_reference_number)
);
COMMENT ON TABLE transactions.financial_transaction IS 'Immutable financial activity register for a Policy recording every contribution, match, rollover, transfer, withdrawal, surrender, fee, and annuity payout.';

-- 5.2 Transaction Fund Allocation Detail
CREATE TABLE IF NOT EXISTS transactions.transaction_fund_allocation_detail (
    transaction_allocation_detail_identifier VARCHAR(64)    NOT NULL,
    financial_transaction_identifier        VARCHAR(64)     NOT NULL,
    holding_account_identifier              VARCHAR(64)     NOT NULL,
    investment_fund_identifier              VARCHAR(64)     NOT NULL,
    transaction_line_number                 INTEGER         NOT NULL,
    allocated_dollar_amount                 NUMERIC(18,2)   NOT NULL,
    unit_price_applied                      NUMERIC(18,6)   NOT NULL DEFAULT 1.000000,
    units_purchased_or_redeemed_count       NUMERIC(18,6)   NOT NULL DEFAULT 0.000000,
    crediting_rate_vintage_assigned         VARCHAR(64)     NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_transaction_fund_allocation_detail PRIMARY KEY (transaction_allocation_detail_identifier),
    CONSTRAINT uq_tfad_tx_line UNIQUE (financial_transaction_identifier, transaction_line_number)
);
COMMENT ON TABLE transactions.transaction_fund_allocation_detail IS 'Breaks down a parent Financial Transaction into individual fund-level and vintage-level debits, credits, unit prices, and unit counts.';

-- 5.3 Non-Financial Service Transaction
CREATE TABLE IF NOT EXISTS transactions.non_financial_service_transaction (
    service_transaction_identifier  VARCHAR(64)     NOT NULL,
    policy_identifier               VARCHAR(64)     NOT NULL,
    service_request_number          VARCHAR(64)     NOT NULL,
    endorsement_type                VARCHAR(120)    NOT NULL,
    request_received_date           DATE            NOT NULL,
    effective_date                  DATE            NOT NULL,
    processed_by_channel            VARCHAR(100)    NOT NULL,
    created_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_non_financial_service_transaction PRIMARY KEY (service_transaction_identifier),
    CONSTRAINT uq_service_request_number UNIQUE (service_request_number)
);
COMMENT ON TABLE transactions.non_financial_service_transaction IS 'Logs administrative and contractual maintenance endorsements performed on a Policy (beneficiary changes, address updates, ownership transfers).';


-- ============================================================================
-- SECTION 7: DOMAIN 6 — REINSURANCE (SCHEMA: reinsurance)
-- ============================================================================

-- 6.1 Reinsurer Counterparty
CREATE TABLE IF NOT EXISTS reinsurance.reinsurer_counterparty (
    reinsurer_counterparty_identifier       VARCHAR(64)     NOT NULL,
    naic_company_code                       VARCHAR(20)     NOT NULL,
    reinsurer_legal_name                    VARCHAR(200)    NOT NULL,
    federal_tax_identification_number       VARCHAR(32)     NOT NULL,
    credit_rating_am_best_or_sp             VARCHAR(64)     NOT NULL,
    authorized_vs_unauthorized_status       VARCHAR(100)    NOT NULL,
    domicile_country                        VARCHAR(100)    NOT NULL,
    collateral_trust_required_indicator     VARCHAR(100)    NOT NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_reinsurer_counterparty PRIMARY KEY (reinsurer_counterparty_identifier),
    CONSTRAINT uq_reinsurer_naic_code UNIQUE (naic_company_code)
);
COMMENT ON TABLE reinsurance.reinsurer_counterparty IS 'Stores master legal, regulatory, NAIC identification, and creditworthiness information for external and captive reinsurance companies.';

-- 6.2 Reinsurance Treaty
CREATE TABLE IF NOT EXISTS reinsurance.reinsurance_treaty (
    reinsurance_treaty_identifier       VARCHAR(64)     NOT NULL,
    treaty_number                       VARCHAR(64)     NOT NULL,
    treaty_name                         VARCHAR(200)    NOT NULL,
    treaty_structure_type               VARCHAR(120)    NOT NULL,
    automatic_vs_facultative_indicator  VARCHAR(100)    NOT NULL,
    treaty_effective_date               DATE            NOT NULL,
    treaty_termination_date             DATE            NULL,
    carrier_retention_limit_amount      NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    cession_percentage                  NUMERIC(9,6)    NOT NULL,
    experience_refund_eligible_indicator VARCHAR(100)   NOT NULL,
    created_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_reinsurance_treaty PRIMARY KEY (reinsurance_treaty_identifier),
    CONSTRAINT uq_reinsurance_treaty_number UNIQUE (treaty_number),
    CONSTRAINT chk_treaty_cession_pct CHECK (cession_percentage >= 0 AND cession_percentage <= 1)
);
COMMENT ON TABLE reinsurance.reinsurance_treaty IS 'Defines formal contractual agreements between the carrier and Reinsurer Counterparties (YRT, Coinsurance, ModCo, Longevity Swap).';

-- 6.3 Reinsurance Treaty Participant
CREATE TABLE IF NOT EXISTS reinsurance.reinsurance_treaty_participant (
    treaty_participant_identifier       VARCHAR(64)     NOT NULL,
    reinsurance_treaty_identifier       VARCHAR(64)     NOT NULL,
    reinsurer_counterparty_identifier   VARCHAR(64)     NOT NULL,
    reinsurer_share_percentage          NUMERIC(9,6)    NOT NULL,
    created_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_reinsurance_treaty_participant PRIMARY KEY (treaty_participant_identifier),
    CONSTRAINT uq_treaty_participant_pair UNIQUE (reinsurance_treaty_identifier, reinsurer_counterparty_identifier),
    CONSTRAINT chk_reinsurer_share_pct CHECK (reinsurer_share_percentage > 0 AND reinsurer_share_percentage <= 1)
);
COMMENT ON TABLE reinsurance.reinsurance_treaty_participant IS 'Associative entity linking a Reinsurance Treaty to one or more participating Reinsurer Counterparties with syndicate share percentages.';

-- 6.4 Reinsured Policy Cession
CREATE TABLE IF NOT EXISTS reinsurance.reinsured_policy_cession (
    cession_identifier              VARCHAR(64)     NOT NULL,
    policy_identifier               VARCHAR(64)     NOT NULL,
    reinsurance_treaty_identifier   VARCHAR(64)     NOT NULL,
    cession_effective_date          DATE            NOT NULL,
    direct_face_amount              NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    retained_risk_amount            NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    ceded_net_amount_at_risk_nar    NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    ceded_reserve_amount            NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    reinsurance_premium_due_amount  NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    expense_allowance_amount        NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    created_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_reinsured_policy_cession PRIMARY KEY (cession_identifier),
    CONSTRAINT uq_policy_treaty_cession_date UNIQUE (policy_identifier, reinsurance_treaty_identifier, cession_effective_date)
);
COMMENT ON TABLE reinsurance.reinsured_policy_cession IS 'Tracks policy-level risk ceded under a Reinsurance Treaty for a specific Policy and valuation period.';

-- 6.5 Reinsurance Claim Recovery
CREATE TABLE IF NOT EXISTS reinsurance.reinsurance_claim_recovery (
    reinsurance_recovery_identifier VARCHAR(64)     NOT NULL,
    cession_identifier              VARCHAR(64)     NOT NULL,
    claim_identifier                VARCHAR(64)     NOT NULL,
    recovery_claim_number           VARCHAR(64)     NOT NULL,
    direct_claim_paid_amount        NUMERIC(18,2)   NOT NULL,
    reinsurance_recoverable_amount  NUMERIC(18,2)   NOT NULL,
    recovery_settlement_status      VARCHAR(100)    NOT NULL,
    recovery_received_date          DATE            NULL,
    created_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_reinsurance_claim_recovery PRIMARY KEY (reinsurance_recovery_identifier),
    CONSTRAINT uq_recovery_claim_number UNIQUE (recovery_claim_number)
);
COMMENT ON TABLE reinsurance.reinsurance_claim_recovery IS 'Manages billing, tracking, and cash collection of reinsured benefit amounts recoverable when a covered Policy experiences a claim.';


-- ============================================================================
-- SECTION 8: DOMAIN 7 — FINANCE (SCHEMA: finance)
-- ============================================================================

-- 7.1 General Ledger Account
CREATE TABLE IF NOT EXISTS finance.general_ledger_account (
    general_ledger_account_identifier       VARCHAR(64)     NOT NULL,
    gl_account_number                       VARCHAR(50)     NOT NULL,
    gl_account_name                         VARCHAR(200)    NOT NULL,
    account_classification                  VARCHAR(100)    NOT NULL,
    accounting_basis                        VARCHAR(100)    NOT NULL,
    separate_vs_general_account_ledger_code VARCHAR(100)    NOT NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_general_ledger_account PRIMARY KEY (general_ledger_account_identifier),
    CONSTRAINT uq_gl_account_number UNIQUE (gl_account_number)
);
COMMENT ON TABLE finance.general_ledger_account IS 'Defines the enterprise insurance Chart of Accounts across US GAAP, Statutory NAIC, and Tax accounting bases.';

-- 7.2 Accounting Period
CREATE TABLE IF NOT EXISTS finance.accounting_period (
    accounting_period_identifier    VARCHAR(64)     NOT NULL,
    fiscal_year                     INTEGER         NOT NULL,
    fiscal_month_or_quarter         VARCHAR(50)     NOT NULL,
    period_start_date               DATE            NOT NULL,
    period_end_date                 DATE            NOT NULL,
    period_close_status             VARCHAR(100)    NOT NULL,
    created_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_accounting_period PRIMARY KEY (accounting_period_identifier),
    CONSTRAINT uq_accounting_period_year_month UNIQUE (fiscal_year, fiscal_month_or_quarter),
    CONSTRAINT chk_accounting_period_dates CHECK (period_end_date >= period_start_date)
);
COMMENT ON TABLE finance.accounting_period IS 'Controls the financial reporting calendar (fiscal months, quarters, and years) and ledger close lifecycle.';

-- 7.3 Sub-Ledger Journal Entry
CREATE TABLE IF NOT EXISTS finance.sub_ledger_journal_entry (
    sub_ledger_journal_entry_identifier     VARCHAR(64)     NOT NULL,
    accounting_period_identifier            VARCHAR(64)     NOT NULL,
    financial_transaction_identifier        VARCHAR(64)     NULL,
    actuarial_valuation_reserve_identifier  VARCHAR(64)     NULL,
    journal_entry_number                    VARCHAR(64)     NOT NULL,
    accounting_event_type                   VARCHAR(120)    NOT NULL,
    posting_date                            DATE            NOT NULL,
    effective_accounting_date               DATE            NOT NULL,
    accounting_basis                        VARCHAR(64)     NOT NULL,
    legal_entity_name                       VARCHAR(200)    NOT NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sub_ledger_journal_entry PRIMARY KEY (sub_ledger_journal_entry_identifier),
    CONSTRAINT uq_sub_ledger_je_number UNIQUE (journal_entry_number)
);
COMMENT ON TABLE finance.sub_ledger_journal_entry IS 'Captures the accounting header generated by policy transactions, actuarial reserve movements, or investment income accruals.';

-- 7.4 Journal Entry Line
CREATE TABLE IF NOT EXISTS finance.journal_entry_line (
    journal_entry_line_identifier               VARCHAR(64)     NOT NULL,
    sub_ledger_journal_entry_identifier         VARCHAR(64)     NOT NULL,
    general_ledger_account_identifier           VARCHAR(64)     NOT NULL,
    ldti_cohort_identifier                      VARCHAR(64)     NULL,
    line_sequence_number                        INTEGER         NOT NULL,
    debit_amount                                NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    credit_amount                               NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    currency_code                               CHAR(3)         NOT NULL DEFAULT 'USD',
    statutory_annual_statement_line_reference   VARCHAR(200)    NULL,
    created_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_journal_entry_line PRIMARY KEY (journal_entry_line_identifier),
    CONSTRAINT uq_je_line_seq UNIQUE (sub_ledger_journal_entry_identifier, line_sequence_number),
    CONSTRAINT chk_je_debit_credit_non_neg CHECK (debit_amount >= 0 AND credit_amount >= 0)
);
COMMENT ON TABLE finance.journal_entry_line IS 'Holds individual balanced debit and credit monetary lines belonging to a Sub-Ledger Journal Entry.';

-- 7.5 General Account Crediting Rate Declaration
CREATE TABLE IF NOT EXISTS finance.general_account_crediting_rate_declaration (
    crediting_rate_declaration_identifier           VARCHAR(64)     NOT NULL,
    product_identifier                              VARCHAR(64)     NOT NULL,
    declaration_effective_date                      DATE            NOT NULL,
    product_code                                    VARCHAR(32)     NOT NULL,
    vintage_period_identifier                       VARCHAR(64)     NOT NULL,
    guaranteed_base_interest_rate                   NUMERIC(9,6)    NOT NULL,
    additional_declared_dividend_or_excess_rate     NUMERIC(9,6)    NOT NULL DEFAULT 0.000000,
    total_effective_crediting_rate                  NUMERIC(9,6)    NOT NULL,
    board_approval_date                             DATE            NOT NULL,
    created_at                                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_ga_crediting_rate_declaration PRIMARY KEY (crediting_rate_declaration_identifier),
    CONSTRAINT uq_ga_crd_prod_vintage_date UNIQUE (product_identifier, vintage_period_identifier, declaration_effective_date)
);
COMMENT ON TABLE finance.general_account_crediting_rate_declaration IS 'Records Board-approved interest rates declared for fixed and general account products (such as general account contribution vintages).';


-- ============================================================================
-- SECTION 9: DOMAIN 8 — EXPERIENCE STUDIES (SCHEMA: experience_studies)
-- ============================================================================

-- 8.1 Experience Study
CREATE TABLE IF NOT EXISTS experience_studies.experience_study (
    experience_study_identifier     VARCHAR(64)     NOT NULL,
    study_name                      VARCHAR(200)    NOT NULL,
    study_type                      VARCHAR(120)    NOT NULL,
    observation_start_date          DATE            NOT NULL,
    observation_end_date            DATE            NOT NULL,
    industry_benchmark_table_name   VARCHAR(150)    NOT NULL,
    study_completion_status         VARCHAR(100)    NOT NULL,
    created_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_experience_study PRIMARY KEY (experience_study_identifier),
    CONSTRAINT chk_exp_study_dates CHECK (observation_end_date >= observation_start_date)
);
COMMENT ON TABLE experience_studies.experience_study IS 'Catalogs formal historical actuarial investigations into policyholder biometric and behavioral events (mortality, longevity, lapse, annuitization).';

-- 8.2 Experience Exposure & Decrement Cohort
CREATE TABLE IF NOT EXISTS experience_studies.experience_exposure_and_decrement_cohort (
    experience_cohort_identifier                VARCHAR(64)     NOT NULL,
    experience_study_identifier                 VARCHAR(64)     NOT NULL,
    product_category                            VARCHAR(100)    NOT NULL,
    attained_age_band                           VARCHAR(50)     NOT NULL,
    policy_duration_year                        INTEGER         NOT NULL,
    gender                                      VARCHAR(32)     NOT NULL,
    smoker_status                               VARCHAR(50)     NOT NULL,
    tax_qualification_type                      VARCHAR(100)    NOT NULL,
    in_the_moneyness_band                       VARCHAR(100)    NOT NULL,
    total_policies_exposed_count                NUMERIC(18,4)   NOT NULL DEFAULT 0.0000,
    total_face_or_account_value_exposed_amount  NUMERIC(20,2)   NOT NULL DEFAULT 0.00,
    actual_decrement_count                      INTEGER         NOT NULL DEFAULT 0,
    actual_decrement_dollar_amount              NUMERIC(20,2)   NOT NULL DEFAULT 0.00,
    expected_decrement_count                    NUMERIC(18,4)   NOT NULL DEFAULT 0.0000,
    actual_to_expected_ae_ratio                 NUMERIC(12,6)   NOT NULL DEFAULT 0.000000,
    created_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_experience_exposure_decrement_cohort PRIMARY KEY (experience_cohort_identifier)
);
COMMENT ON TABLE experience_studies.experience_exposure_and_decrement_cohort IS 'Stores aggregated exposure counts, face/account values exposed, actual vs expected decrements, and A/E ratios by cohort cell.';

-- 8.3 Experience Study Policy Observation
CREATE TABLE IF NOT EXISTS experience_studies.experience_study_policy_observation (
    policy_observation_identifier   VARCHAR(64)     NOT NULL,
    experience_study_identifier     VARCHAR(64)     NOT NULL,
    policy_identifier               VARCHAR(64)     NOT NULL,
    claim_identifier                VARCHAR(64)     NULL,
    exposure_fraction_years         NUMERIC(9,6)    NOT NULL DEFAULT 1.000000,
    decrement_indicator             INTEGER         NOT NULL DEFAULT 0,
    created_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_experience_study_policy_observation PRIMARY KEY (policy_observation_identifier),
    CONSTRAINT chk_espo_exposure_fraction CHECK (exposure_fraction_years >= 0 AND exposure_fraction_years <= 1),
    CONSTRAINT chk_espo_decrement_flag CHECK (decrement_indicator IN (0, 1))
);
COMMENT ON TABLE experience_studies.experience_study_policy_observation IS 'Associative policy-year observation record linking an Experience Study to individual historical Policies and Claims.';


-- ============================================================================
-- SECTION 10: DOMAIN 9 — ACTUARIAL (SCHEMA: actuarial)
-- ============================================================================

-- 9.1 Actuarial Assumption Set
CREATE TABLE IF NOT EXISTS actuarial.actuarial_assumption_set (
    actuarial_assumption_set_identifier VARCHAR(64)     NOT NULL,
    experience_study_identifier         VARCHAR(64)     NULL,
    assumption_set_name                 VARCHAR(200)    NOT NULL,
    assumption_version_number           VARCHAR(32)     NOT NULL,
    valuation_purpose                   VARCHAR(120)    NOT NULL,
    effective_valuation_date            DATE            NOT NULL,
    base_mortality_or_longevity_table   VARCHAR(150)    NOT NULL,
    mortality_improvement_scale         VARCHAR(120)    NOT NULL,
    dynamic_lapse_formula_type          VARCHAR(150)    NOT NULL,
    discount_rate_curve_reference       VARCHAR(150)    NOT NULL,
    assumed_annuitization_utilization_rate VARCHAR(150) NOT NULL,
    governance_approval_status          VARCHAR(100)    NOT NULL,
    created_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_actuarial_assumption_set PRIMARY KEY (actuarial_assumption_set_identifier),
    CONSTRAINT uq_assumption_set_name_ver UNIQUE (assumption_set_name, assumption_version_number)
);
COMMENT ON TABLE actuarial.actuarial_assumption_set IS 'Holds version-controlled, governance-approved mortality tables, longevity scales, dynamic lapse formulas, and discount curves.';

-- 9.2 LDTI Valuation Cohort
CREATE TABLE IF NOT EXISTS actuarial.ldti_valuation_cohort (
    ldti_cohort_identifier              VARCHAR(64)     NOT NULL,
    product_issue_year                  INTEGER         NOT NULL,
    product_grouping_name               VARCHAR(200)    NOT NULL,
    locked_in_discount_rate             NUMERIC(9,6)    NOT NULL,
    current_market_discount_rate        NUMERIC(9,6)    NOT NULL,
    deferred_acquisition_cost_dac_balance NUMERIC(20,2) NOT NULL DEFAULT 0.00,
    market_risk_benefit_mrb_fair_value  NUMERIC(20,2)   NOT NULL DEFAULT 0.00,
    created_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_ldti_valuation_cohort PRIMARY KEY (ldti_cohort_identifier),
    CONSTRAINT uq_ldti_grouping_year UNIQUE (product_grouping_name, product_issue_year)
);
COMMENT ON TABLE actuarial.ldti_valuation_cohort IS 'US GAAP Long-Duration Targeted Improvements (ASC 944) aggregation unit tracking locked-in discount rates, DAC, and Market Risk Benefits (MRB).';

-- 9.3 Actuarial Valuation Reserve
CREATE TABLE IF NOT EXISTS actuarial.actuarial_valuation_reserve (
    actuarial_valuation_reserve_identifier      VARCHAR(64)     NOT NULL,
    policy_identifier                           VARCHAR(64)     NOT NULL,
    actuarial_assumption_set_identifier         VARCHAR(64)     NOT NULL,
    ldti_cohort_identifier                      VARCHAR(64)     NULL,
    valuation_date                              DATE            NOT NULL,
    valuation_basis                             VARCHAR(100)    NOT NULL,
    net_premium_reserve_amount                  NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    deterministic_reserve_amount                NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    stochastic_reserve_amount                   NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    future_policy_benefit_reserve_amount        NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    additional_actuarial_reserve_aar_amount     NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    net_amount_at_risk_nar                      NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    required_risk_based_capital_rbc_amount      NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    created_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_actuarial_valuation_reserve PRIMARY KEY (actuarial_valuation_reserve_identifier),
    CONSTRAINT uq_policy_val_date_basis UNIQUE (policy_identifier, valuation_date, valuation_basis)
);
COMMENT ON TABLE actuarial.actuarial_valuation_reserve IS 'Stores calculated policy-level or model-point-level liability reserves across Statutory (VM-20/21/22), US GAAP LDTI, and Tax bases.';

-- 9.4 Actuarial Cash Flow Projection
CREATE TABLE IF NOT EXISTS actuarial.actuarial_cash_flow_projection (
    cash_flow_projection_identifier         VARCHAR(64)     NOT NULL,
    actuarial_assumption_set_identifier     VARCHAR(64)     NOT NULL,
    policy_identifier                       VARCHAR(64)     NULL,
    projection_run_identifier               VARCHAR(64)     NOT NULL,
    economic_scenario_number                INTEGER         NOT NULL,
    projection_month_or_year                VARCHAR(50)     NOT NULL,
    projected_premium_inflow_amount         NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    projected_death_benefit_outflow         NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    projected_annuity_income_outflow        NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    projected_surrender_outflow             NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    projected_net_investment_income         NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_actuarial_cash_flow_projection PRIMARY KEY (cash_flow_projection_identifier)
);
COMMENT ON TABLE actuarial.actuarial_cash_flow_projection IS 'Captures period-by-period deterministic and stochastic projected inflows and outflows across economic scenarios for ALM and Cash Flow Testing.';


-- ============================================================================
-- SECTION 11: DOMAIN 10 — AGENT & AGENCY (SCHEMA: agent_and_agency)
-- ============================================================================

-- 10.1 Agency
CREATE TABLE IF NOT EXISTS agent_and_agency.agency (
    agency_identifier                   VARCHAR(64)     NOT NULL,
    national_producer_number_npn_entity VARCHAR(32)     NOT NULL,
    broker_dealer_crd_number            VARCHAR(32)     NULL,
    agency_name                         VARCHAR(200)    NOT NULL,
    agency_type                         VARCHAR(120)    NOT NULL,
    selling_agreement_status            VARCHAR(100)    NOT NULL,
    contract_effective_date             DATE            NOT NULL,
    created_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_agency PRIMARY KEY (agency_identifier),
    CONSTRAINT uq_agency_npn_entity UNIQUE (national_producer_number_npn_entity)
);
COMMENT ON TABLE agent_and_agency.agency IS 'Represents an internal wealth advisory division, Broker-Dealer partner (e.g., LPL Financial), IMO, or bank authorized under a selling agreement.';

-- 10.2 Producer / Advisor
CREATE TABLE IF NOT EXISTS agent_and_agency.producer_advisor (
    producer_identifier             VARCHAR(64)     NOT NULL,
    agency_identifier               VARCHAR(64)     NOT NULL,
    national_producer_number_npn    VARCHAR(32)     NOT NULL,
    finra_crd_number                VARCHAR(32)     NULL,
    producer_full_name              VARCHAR(150)    NOT NULL,
    producer_role_type              VARCHAR(120)    NOT NULL,
    active_status                   VARCHAR(100)    NOT NULL,
    onboarding_date                 DATE            NOT NULL,
    created_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_producer_advisor PRIMARY KEY (producer_identifier),
    CONSTRAINT uq_producer_npn UNIQUE (national_producer_number_npn)
);
COMMENT ON TABLE agent_and_agency.producer_advisor IS 'Holds the master profile of an individual licensed insurance agent, wealth management advisor, or institutional relationship manager.';

-- 10.3 Producer License & Carrier Appointment
CREATE TABLE IF NOT EXISTS agent_and_agency.producer_license_and_carrier_appointment (
    license_and_appointment_identifier          VARCHAR(64)     NOT NULL,
    producer_identifier                         VARCHAR(64)     NOT NULL,
    state_jurisdiction                          VARCHAR(10)     NOT NULL,
    license_number                              VARCHAR(64)     NOT NULL,
    line_of_authority                           VARCHAR(150)    NOT NULL,
    license_expiration_date                     DATE            NOT NULL,
    carrier_appointment_status                  VARCHAR(100)    NOT NULL,
    finra_series_qualification                  VARCHAR(150)    NULL,
    product_training_and_reg_bi_completion_date DATE            NULL,
    created_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_producer_license_appointment PRIMARY KEY (license_and_appointment_identifier),
    CONSTRAINT uq_producer_state_license UNIQUE (producer_identifier, state_jurisdiction, license_number)
);
COMMENT ON TABLE agent_and_agency.producer_license_and_carrier_appointment IS 'Tracks state insurance licenses, lines of authority, FINRA series registrations, carrier appointments, and NAIC Best Interest training.';

-- 10.4 Policy Producer Assignment
CREATE TABLE IF NOT EXISTS agent_and_agency.policy_producer_assignment (
    policy_producer_assignment_identifier   VARCHAR(64)     NOT NULL,
    policy_identifier                       VARCHAR(64)     NOT NULL,
    producer_identifier                     VARCHAR(64)     NOT NULL,
    agency_identifier                       VARCHAR(64)     NOT NULL,
    assignment_role                         VARCHAR(100)    NOT NULL,
    commission_split_percentage             NUMERIC(9,6)    NOT NULL DEFAULT 1.000000,
    assignment_effective_date               DATE            NOT NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_policy_producer_assignment PRIMARY KEY (policy_producer_assignment_identifier),
    CONSTRAINT chk_ppa_split_pct CHECK (commission_split_percentage >= 0 AND commission_split_percentage <= 1)
);
COMMENT ON TABLE agent_and_agency.policy_producer_assignment IS 'Links one or more Producers and Agencies to a Policy, defining writing/servicing role and commission split percentage.';

-- 10.5 Compensation Schedule & Commission Statement
CREATE TABLE IF NOT EXISTS agent_and_agency.compensation_schedule_and_commission_statement (
    commission_statement_line_identifier    VARCHAR(64)     NOT NULL,
    policy_producer_assignment_identifier   VARCHAR(64)     NOT NULL,
    financial_transaction_identifier        VARCHAR(64)     NULL,
    commission_schedule_code                VARCHAR(64)     NOT NULL,
    compensation_type                       VARCHAR(120)    NOT NULL,
    commission_rate_percentage              NUMERIC(9,6)    NOT NULL DEFAULT 0.000000,
    earned_commission_amount                NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    chargeback_recovery_amount              NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    statement_payment_date                  DATE            NOT NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_compensation_commission_statement PRIMARY KEY (commission_statement_line_identifier)
);
COMMENT ON TABLE agent_and_agency.compensation_schedule_and_commission_statement IS 'Records commission calculation rules and periodic commission payout statements (upfront, trails, advisory fees, chargebacks).';


-- ============================================================================
-- SECTION 12: DOMAIN 11 — PARTY, CUSTOMER & HOUSEHOLD
--             (SCHEMA: party_customer_and_household)
-- ============================================================================

-- 11.1 Party
CREATE TABLE IF NOT EXISTS party_customer_and_household.party (
    party_identifier                        VARCHAR(64)     NOT NULL,
    party_type                              VARCHAR(100)    NOT NULL,
    full_legal_name                         VARCHAR(200)    NOT NULL,
    date_of_birth                           DATE            NULL,
    date_of_death                           DATE            NULL,
    gender                                  VARCHAR(50)     NULL,
    marital_status                          VARCHAR(64)     NULL,
    tax_identification_number_ssn_ein       VARCHAR(64)     NOT NULL,
    citizenship_and_tax_residency_status    VARCHAR(100)    NOT NULL,
    smoking_or_tobacco_status               VARCHAR(100)    NULL,
    occupation_class                        VARCHAR(120)    NULL,
    primary_residence_state                 VARCHAR(10)     NOT NULL,
    kyc_and_aml_verification_status         VARCHAR(100)    NOT NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_party PRIMARY KEY (party_identifier),
    CONSTRAINT chk_party_birth_death_dates CHECK (date_of_death IS NULL OR date_of_birth IS NULL OR date_of_death >= date_of_birth)
);
COMMENT ON TABLE party_customer_and_household.party IS 'Enterprise Master Data Management (MDM) golden record for every individual person and legal organization across all policies, plans, and claims.';

-- 11.2 Party Contact & Address Profile
CREATE TABLE IF NOT EXISTS party_customer_and_household.party_contact_and_address_profile (
    contact_profile_identifier              VARCHAR(64)     NOT NULL,
    party_identifier                        VARCHAR(64)     NOT NULL,
    address_type                            VARCHAR(100)    NOT NULL,
    street_address                          VARCHAR(250)    NOT NULL,
    city                                    VARCHAR(100)    NOT NULL,
    state_or_province                       VARCHAR(50)     NOT NULL,
    postal_code                             VARCHAR(32)     NOT NULL,
    country                                 VARCHAR(100)    NOT NULL DEFAULT 'United States',
    primary_phone_number                    VARCHAR(50)     NULL,
    electronic_delivery_consent_indicator   VARCHAR(100)    NOT NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_party_contact_address_profile PRIMARY KEY (contact_profile_identifier)
);
COMMENT ON TABLE party_customer_and_household.party_contact_and_address_profile IS 'Stores residential, mailing, tax reporting, and digital contact information for a Party, plus e-Delivery consent and RPO flags.';

-- 11.3 Household
CREATE TABLE IF NOT EXISTS party_customer_and_household.household (
    household_identifier                    VARCHAR(64)     NOT NULL,
    primary_household_head_party_identifier VARCHAR(64)     NOT NULL,
    household_name                          VARCHAR(200)    NOT NULL,
    household_tier_segment                  VARCHAR(100)    NOT NULL,
    total_household_aggregated_assets       NUMERIC(20,2)   NOT NULL DEFAULT 0.00,
    household_formation_date                DATE            NOT NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_household PRIMARY KEY (household_identifier)
);
COMMENT ON TABLE party_customer_and_household.household IS 'Aggregates related individual Parties and their associated policies and retirement accounts into a single family or wealth relationship unit.';

-- 11.4 Household Member Assignment
CREATE TABLE IF NOT EXISTS party_customer_and_household.household_member_assignment (
    household_member_assignment_identifier  VARCHAR(64)     NOT NULL,
    household_identifier                    VARCHAR(64)     NOT NULL,
    party_identifier                        VARCHAR(64)     NOT NULL,
    household_relationship_role             VARCHAR(100)    NOT NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_household_member_assignment PRIMARY KEY (household_member_assignment_identifier),
    CONSTRAINT uq_household_party_member UNIQUE (household_identifier, party_identifier)
);
COMMENT ON TABLE party_customer_and_household.household_member_assignment IS 'Links individual Parties to a Household with relationship roles (Primary Head, Spouse/Partner, Dependent, Family Trust).';

-- 11.5 Policy Party Role
CREATE TABLE IF NOT EXISTS party_customer_and_household.policy_party_role (
    policy_party_role_identifier                VARCHAR(64)     NOT NULL,
    policy_identifier                           VARCHAR(64)     NOT NULL,
    party_identifier                            VARCHAR(64)     NOT NULL,
    role_type                                   VARCHAR(100)    NOT NULL,
    beneficiary_share_percentage                NUMERIC(9,6)    NOT NULL DEFAULT 0.000000,
    per_stirpes_vs_per_capita_indicator         VARCHAR(100)    NOT NULL DEFAULT 'Not Applicable',
    revocable_vs_irrevocable_indicator          VARCHAR(100)    NOT NULL DEFAULT 'Not Applicable',
    relationship_to_primary_insured_annuitant   VARCHAR(100)    NOT NULL,
    role_effective_date                         DATE            NOT NULL,
    role_end_date                               DATE            NULL,
    created_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_policy_party_role PRIMARY KEY (policy_party_role_identifier),
    CONSTRAINT chk_ppr_ben_share_pct CHECK (beneficiary_share_percentage >= 0 AND beneficiary_share_percentage <= 1),
    CONSTRAINT chk_ppr_role_dates CHECK (role_end_date IS NULL OR role_end_date >= role_effective_date)
);
COMMENT ON TABLE party_customer_and_household.policy_party_role IS 'Resolves the many-to-many relationship between Parties and Policies (Owner, Plan Participant, Insured, Annuitant, Primary/Contingent Beneficiary).';


-- ============================================================================
-- SECTION 13: DOMAIN 12 — INSTITUTIONAL PLAN & EMPLOYER SPONSOR
--             (SCHEMA: institutional_plan_and_employer_sponsor)
-- ============================================================================

-- 12.1 Employer Sponsor Organization
CREATE TABLE IF NOT EXISTS institutional_plan_and_employer_sponsor.employer_sponsor_organization (
    employer_sponsor_identifier             VARCHAR(64)     NOT NULL,
    party_identifier                        VARCHAR(64)     NOT NULL,
    employer_identification_number_ein      VARCHAR(32)     NOT NULL,
    institution_legal_name                  VARCHAR(200)    NOT NULL,
    institution_sector                      VARCHAR(150)    NOT NULL,
    master_services_agreement_effective_date DATE           NOT NULL,
    relationship_manager_assigned           VARCHAR(150)    NOT NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_employer_sponsor_organization PRIMARY KEY (employer_sponsor_identifier),
    CONSTRAINT uq_employer_sponsor_ein UNIQUE (employer_identification_number_ein)
);
COMMENT ON TABLE institutional_plan_and_employer_sponsor.employer_sponsor_organization IS 'Represents a university, hospital system, school district, research institute, or corporate employer sponsoring retirement plans.';

-- 12.2 Institutional Retirement Plan
CREATE TABLE IF NOT EXISTS institutional_plan_and_employer_sponsor.institutional_retirement_plan (
    institutional_plan_identifier               VARCHAR(64)     NOT NULL,
    employer_sponsor_identifier                 VARCHAR(64)     NOT NULL,
    default_investment_option_qdia_fund_id      VARCHAR(64)     NULL,
    plan_number                                 VARCHAR(64)     NOT NULL,
    plan_official_name                          VARCHAR(200)    NOT NULL,
    plan_tax_code_type                          VARCHAR(120)    NOT NULL,
    plan_effective_date                         DATE            NOT NULL,
    auto_enrollment_enabled_indicator           VARCHAR(100)    NOT NULL,
    auto_escalation_default_percentage          NUMERIC(9,6)    NOT NULL DEFAULT 0.000000,
    plan_loan_permitted_indicator               VARCHAR(100)    NOT NULL,
    maximum_active_loans_allowed                INTEGER         NOT NULL DEFAULT 0,
    hardship_withdrawal_permitted_indicator     VARCHAR(100)    NOT NULL,
    created_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_institutional_retirement_plan PRIMARY KEY (institutional_plan_identifier),
    CONSTRAINT uq_institutional_plan_number UNIQUE (plan_number),
    CONSTRAINT chk_plan_max_loans CHECK (maximum_active_loans_allowed >= 0)
);
COMMENT ON TABLE institutional_plan_and_employer_sponsor.institutional_retirement_plan IS 'Captures master plan document terms for an employer-sponsored retirement plan (403(b), 401(a), 457(b), 401(k)).';

-- 12.3 Plan Eligibility & Contribution Rule
CREATE TABLE IF NOT EXISTS institutional_plan_and_employer_sponsor.plan_eligibility_and_contribution_rule (
    plan_eligibility_rule_identifier            VARCHAR(64)     NOT NULL,
    institutional_plan_identifier               VARCHAR(64)     NOT NULL,
    employee_classification_group               VARCHAR(150)    NOT NULL,
    minimum_service_waiting_period_months       INTEGER         NOT NULL DEFAULT 0,
    employer_base_contribution_percentage       NUMERIC(9,6)    NOT NULL DEFAULT 0.000000,
    employer_matching_formula_description       VARCHAR(250)    NOT NULL,
    maximum_employer_match_cap_percentage       NUMERIC(9,6)    NOT NULL DEFAULT 0.000000,
    mandatory_employee_contribution_percentage  NUMERIC(9,6)    NOT NULL DEFAULT 0.000000,
    created_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_plan_eligibility_contribution_rule PRIMARY KEY (plan_eligibility_rule_identifier),
    CONSTRAINT chk_pecr_waiting_months CHECK (minimum_service_waiting_period_months >= 0)
);
COMMENT ON TABLE institutional_plan_and_employer_sponsor.plan_eligibility_and_contribution_rule IS 'Defines employee class eligibility waiting periods, mandatory salary deferral rates, and employer basic/matching contribution formulas.';

-- 12.4 Plan Vesting Schedule
CREATE TABLE IF NOT EXISTS institutional_plan_and_employer_sponsor.plan_vesting_schedule (
    plan_vesting_schedule_identifier            VARCHAR(64)     NOT NULL,
    institutional_plan_identifier               VARCHAR(64)     NOT NULL,
    vesting_schedule_type                       VARCHAR(150)    NOT NULL,
    contribution_source_covered                 VARCHAR(150)    NOT NULL,
    years_of_service_required_for_full_vesting  INTEGER         NOT NULL DEFAULT 0,
    forfeiture_reallocation_rule                VARCHAR(150)    NOT NULL,
    created_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_plan_vesting_schedule PRIMARY KEY (plan_vesting_schedule_identifier),
    CONSTRAINT chk_pvs_vesting_years CHECK (years_of_service_required_for_full_vesting >= 0)
);
COMMENT ON TABLE institutional_plan_and_employer_sponsor.plan_vesting_schedule IS 'Specifies years-of-service vesting rules (immediate, cliff, graded) governing non-forfeitable ownership of employer contributions.';


-- ============================================================================
-- SECTION 14: DOMAIN 13 — UNDERWRITING & NEW BUSINESS
--             (SCHEMA: underwriting_and_new_business)
-- ============================================================================

-- 13.1 Quote & Policy Illustration
CREATE TABLE IF NOT EXISTS underwriting_and_new_business.quote_and_policy_illustration (
    illustration_identifier                         VARCHAR(64)     NOT NULL,
    product_identifier                              VARCHAR(64)     NOT NULL,
    producer_identifier                             VARCHAR(64)     NOT NULL,
    illustration_number                             VARCHAR(64)     NOT NULL,
    illustration_preparation_date                   DATE            NOT NULL,
    proposed_product_name                           VARCHAR(200)    NOT NULL,
    illustrated_initial_contribution_or_face_amount NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    illustrated_periodic_premium_amount             NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    guaranteed_values_projection_summary            VARCHAR(500)    NOT NULL,
    non_guaranteed_assumed_crediting_rate           NUMERIC(9,6)    NOT NULL DEFAULT 0.000000,
    signed_illustration_received_indicator          VARCHAR(100)    NOT NULL,
    created_at                                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_quote_and_policy_illustration PRIMARY KEY (illustration_identifier),
    CONSTRAINT uq_illustration_number UNIQUE (illustration_number)
);
COMMENT ON TABLE underwriting_and_new_business.quote_and_policy_illustration IS 'Stores pre-sale hypothetical and guaranteed ledger projections presented to a prospective customer for a Life or Annuity product.';

-- 13.2 Application
CREATE TABLE IF NOT EXISTS underwriting_and_new_business.application (
    application_identifier                      VARCHAR(64)     NOT NULL,
    illustration_identifier                     VARCHAR(64)     NULL,
    product_identifier                          VARCHAR(64)     NOT NULL,
    applicant_party_identifier                  VARCHAR(64)     NOT NULL,
    application_number                          VARCHAR(64)     NOT NULL,
    submission_date                             DATE            NOT NULL,
    application_channel                         VARCHAR(120)    NOT NULL,
    application_type                            VARCHAR(120)    NOT NULL,
    requested_face_amount                       NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    planned_initial_contribution_amount         NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    existing_insurance_replacement_indicator    VARCHAR(120)    NOT NULL,
    electronic_signature_status                 VARCHAR(100)    NOT NULL,
    application_status                          VARCHAR(100)    NOT NULL,
    created_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_application PRIMARY KEY (application_identifier),
    CONSTRAINT uq_application_number UNIQUE (application_number)
);
COMMENT ON TABLE underwriting_and_new_business.application IS 'Captures a formal new business submission or institutional plan enrollment request to purchase a Life or Annuity contract.';

-- 13.3 Underwriting Case & Risk Decision
CREATE TABLE IF NOT EXISTS underwriting_and_new_business.underwriting_case_and_risk_decision (
    underwriting_case_identifier            VARCHAR(64)     NOT NULL,
    application_identifier                  VARCHAR(64)     NOT NULL,
    insured_party_identifier                VARCHAR(64)     NOT NULL,
    underwriting_case_number                VARCHAR(64)     NOT NULL,
    underwriting_method                     VARCHAR(120)    NOT NULL,
    underwriter_assigned_name               VARCHAR(150)    NOT NULL,
    assigned_mortality_risk_classification  VARCHAR(120)    NOT NULL,
    substandard_table_rating_factor         VARCHAR(100)    NOT NULL,
    flat_extra_premium_per_thousand_amount  NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    underwriting_decision_date              DATE            NULL,
    final_underwriting_decision             VARCHAR(120)    NOT NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_underwriting_case_risk_decision PRIMARY KEY (underwriting_case_identifier),
    CONSTRAINT uq_underwriting_case_number UNIQUE (underwriting_case_number)
);
COMMENT ON TABLE underwriting_and_new_business.underwriting_case_and_risk_decision IS 'Manages mortality and financial risk evaluation of an Application and records final approved risk class, table rating, or decline decision.';

-- 13.4 Medical & Mortality Requirement
CREATE TABLE IF NOT EXISTS underwriting_and_new_business.medical_and_mortality_requirement (
    underwriting_requirement_identifier VARCHAR(64)     NOT NULL,
    underwriting_case_identifier        VARCHAR(64)     NOT NULL,
    requirement_type                    VARCHAR(150)    NOT NULL,
    ordered_date                        DATE            NOT NULL,
    received_date                       DATE            NULL,
    requirement_evaluation_result       VARCHAR(250)    NULL,
    requirement_status                  VARCHAR(100)    NOT NULL,
    created_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_medical_and_mortality_requirement PRIMARY KEY (underwriting_requirement_identifier)
);
COMMENT ON TABLE underwriting_and_new_business.medical_and_mortality_requirement IS 'Tracks individual underwriting evidence items ordered to evaluate mortality risk (APS, paramed exam, blood labs, Rx history, MIB, MVR).';


-- ============================================================================
-- SECTION 15: DOMAIN 14 — CLAIMS, ANNUITIZATION & BENEFIT PAYOUTS
--             (SCHEMA: claims_annuitization_and_benefit_payouts)
-- ============================================================================

-- 14.1 Annuitization Payout Schedule (Lifetime Income Core)
CREATE TABLE IF NOT EXISTS claims_annuitization_and_benefit_payouts.annuitization_payout_schedule (
    annuitization_payout_schedule_identifier        VARCHAR(64)     NOT NULL,
    policy_identifier                               VARCHAR(64)     NOT NULL,
    primary_annuitant_party_identifier              VARCHAR(64)     NOT NULL,
    joint_survivor_annuitant_party_identifier       VARCHAR(64)     NULL,
    payout_contract_number                          VARCHAR(64)     NOT NULL,
    annuitization_effective_date                    DATE            NOT NULL,
    first_income_payment_date                       DATE            NOT NULL,
    payout_option_type                              VARCHAR(150)    NOT NULL,
    payment_frequency                               VARCHAR(50)     NOT NULL,
    guaranteed_minimum_periodic_payment_amount      NUMERIC(18,2)   NOT NULL,
    current_variable_or_additional_dividend_amount  NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    assumed_investment_return_air_election          VARCHAR(100)    NOT NULL,
    guaranteed_period_certain_end_date              DATE            NULL,
    created_at                                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_annuitization_payout_schedule PRIMARY KEY (annuitization_payout_schedule_identifier),
    CONSTRAINT uq_payout_contract_number UNIQUE (payout_contract_number),
    CONSTRAINT chk_aps_payment_dates CHECK (first_income_payment_date >= annuitization_effective_date)
);
COMMENT ON TABLE claims_annuitization_and_benefit_payouts.annuitization_payout_schedule IS 'Governs the income phase of an annuity contract after converting savings into guaranteed lifetime or fixed-period income.';

-- 14.2 Required Minimum Distribution (RMD) Schedule
CREATE TABLE IF NOT EXISTS claims_annuitization_and_benefit_payouts.required_minimum_distribution_schedule (
    rmd_schedule_identifier                         VARCHAR(64)     NOT NULL,
    policy_identifier                               VARCHAR(64)     NOT NULL,
    tax_calendar_year                               INTEGER         NOT NULL,
    applicable_irs_life_expectancy_table            VARCHAR(150)    NOT NULL,
    prior_year_december_31_fair_market_value        NUMERIC(18,2)   NOT NULL,
    actuarial_present_value_additional_benefits     NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    calculated_annual_rmd_amount                    NUMERIC(18,2)   NOT NULL,
    satisfied_rmd_amount_year_to_date               NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    remaining_rmd_amount_due                        NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    automated_rmd_payout_election_indicator         VARCHAR(150)    NOT NULL,
    created_at                                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_required_minimum_distribution_schedule PRIMARY KEY (rmd_schedule_identifier),
    CONSTRAINT uq_rmd_policy_tax_year UNIQUE (policy_identifier, tax_calendar_year)
);
COMMENT ON TABLE claims_annuitization_and_benefit_payouts.required_minimum_distribution_schedule IS 'Calculates and tracks mandatory annual withdrawals under IRC Section 401(a)(9) based on prior year-end FMV and IRS life expectancy tables.';

-- 14.3 Claim & Benefit Settlement
CREATE TABLE IF NOT EXISTS claims_annuitization_and_benefit_payouts.claim_and_benefit_settlement (
    claim_identifier                                VARCHAR(64)     NOT NULL,
    policy_identifier                               VARCHAR(64)     NOT NULL,
    insured_or_annuitant_party_identifier           VARCHAR(64)     NOT NULL,
    claim_number                                    VARCHAR(64)     NOT NULL,
    claim_type                                      VARCHAR(150)    NOT NULL,
    date_of_loss_or_death                           DATE            NOT NULL,
    claim_notification_date                         DATE            NOT NULL,
    proof_of_death_or_loss_verified_date            DATE            NULL,
    base_contract_benefit_amount                    NUMERIC(18,2)   NOT NULL,
    guaranteed_minimum_death_benefit_step_up_amount NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    delayed_settlement_interest_credited_amount     NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    less_outstanding_policy_loan_balance            NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    net_payable_claim_benefit_amount                NUMERIC(18,2)   NOT NULL,
    claim_status                                    VARCHAR(100)    NOT NULL,
    created_at                                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_claim_and_benefit_settlement PRIMARY KEY (claim_identifier),
    CONSTRAINT uq_claim_number UNIQUE (claim_number),
    CONSTRAINT chk_claim_dates CHECK (claim_notification_date >= date_of_loss_or_death)
);
COMMENT ON TABLE claims_annuitization_and_benefit_payouts.claim_and_benefit_settlement IS 'Manages end-to-end adjudication and financial calculation of Death Benefit, Living Benefit, Disability Waiver, and Maturity claims.';

-- 14.4 Beneficiary Claim Payout Election
CREATE TABLE IF NOT EXISTS claims_annuitization_and_benefit_payouts.beneficiary_claim_payout_election (
    beneficiary_payout_election_identifier  VARCHAR(64)     NOT NULL,
    claim_identifier                        VARCHAR(64)     NOT NULL,
    beneficiary_party_identifier            VARCHAR(64)     NOT NULL,
    elected_settlement_method               VARCHAR(150)    NOT NULL,
    share_percentage_paid                   NUMERIC(9,6)    NOT NULL,
    disbursement_date                       DATE            NULL,
    payment_method                          VARCHAR(100)    NOT NULL,
    created_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_beneficiary_claim_payout_election PRIMARY KEY (beneficiary_payout_election_identifier),
    CONSTRAINT chk_bcpe_share_pct CHECK (share_percentage_paid > 0 AND share_percentage_paid <= 1)
);
COMMENT ON TABLE claims_annuitization_and_benefit_payouts.beneficiary_claim_payout_election IS 'Records each individual beneficiary verified claim share and elected settlement method (lump sum, spousal continuation, 10-yr inherited stretch).';


-- ============================================================================
-- SECTION 16: DOMAIN 15 — BILLING, REMITTANCE & TAX REPORTING
--             (SCHEMA: billing_remittance_and_tax_reporting)
-- ============================================================================

-- 15.1 Institutional Payroll Remittance Batch
CREATE TABLE IF NOT EXISTS billing_remittance_and_tax_reporting.institutional_payroll_remittance_batch (
    remittance_batch_identifier                 VARCHAR(64)     NOT NULL,
    institutional_plan_identifier               VARCHAR(64)     NOT NULL,
    remittance_batch_number                     VARCHAR(64)     NOT NULL,
    payroll_pay_period_end_date                 DATE            NOT NULL,
    remittance_file_received_date               DATE            NOT NULL,
    wire_or_ach_settlement_date                 DATE            NULL,
    total_employee_pre_tax_contribution_amount  NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    total_employee_roth_after_tax_amount        NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    total_employer_matching_contribution_amount NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    total_employer_basic_contribution_amount    NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    total_loan_repayment_amount                 NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    batch_reconciliation_status                 VARCHAR(120)    NOT NULL,
    created_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_institutional_payroll_remittance_batch PRIMARY KEY (remittance_batch_identifier),
    CONSTRAINT uq_remittance_batch_number UNIQUE (remittance_batch_number)
);
COMMENT ON TABLE billing_remittance_and_tax_reporting.institutional_payroll_remittance_batch IS 'Tracks bulk payroll contribution files and wire/ACH cash remittances submitted by an Employer Sponsor for an Institutional Retirement Plan.';

-- 15.2 Billing & Tax Withholding Schedule
CREATE TABLE IF NOT EXISTS billing_remittance_and_tax_reporting.billing_and_tax_withholding_schedule (
    billing_and_withholding_schedule_identifier         VARCHAR(64)     NOT NULL,
    policy_identifier                                   VARCHAR(64)     NOT NULL,
    billing_mode                                        VARCHAR(100)    NOT NULL,
    billed_modal_premium_amount                         NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    next_bill_due_date                                  DATE            NULL,
    grace_period_expiration_date                        DATE            NULL,
    federal_income_tax_withholding_election_type        VARCHAR(150)    NOT NULL,
    federal_withholding_percentage_or_dollar_amount     NUMERIC(18,4)   NOT NULL DEFAULT 0.0000,
    state_income_tax_withholding_pct_or_dollar_amount   NUMERIC(18,4)   NOT NULL DEFAULT 0.0000,
    created_at                                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_billing_and_tax_withholding_schedule PRIMARY KEY (billing_and_withholding_schedule_identifier)
);
COMMENT ON TABLE billing_remittance_and_tax_reporting.billing_and_tax_withholding_schedule IS 'Stores recurring premium billing frequency, EFT draft instructions, grace period dates, and standing Federal (W-4P/W-4R) and State tax withholding elections.';

-- 15.3 Tax Reporting Statement (IRS 1099-R / 5498)
CREATE TABLE IF NOT EXISTS billing_remittance_and_tax_reporting.tax_reporting_statement (
    tax_statement_identifier                        VARCHAR(64)     NOT NULL,
    policy_identifier                               VARCHAR(64)     NOT NULL,
    recipient_party_identifier                      VARCHAR(64)     NOT NULL,
    tax_year                                        INTEGER         NOT NULL,
    tax_form_type                                   VARCHAR(150)    NOT NULL,
    gross_distribution_amount_box_1                 NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    taxable_amount_box_2a                           NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    taxable_amount_not_determined_indicator         VARCHAR(100)    NOT NULL,
    federal_income_tax_withheld_box_4               NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    employee_after_tax_basis_recovered_box_5        NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    irs_distribution_code_box_7                     VARCHAR(50)     NULL,
    rollover_contributions_amount                   NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    december_31_fair_market_value                   NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    correction_or_amended_filing_indicator          VARCHAR(100)    NOT NULL DEFAULT 'Original Tax Filing',
    created_at                                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tax_reporting_statement PRIMARY KEY (tax_statement_identifier)
);
COMMENT ON TABLE billing_remittance_and_tax_reporting.tax_reporting_statement IS 'Stores annual regulatory tax forms issued to policyholders and filed with the IRS (Form 1099-R, Form 5498, Form 1099-INT, Form 1042-S).';


-- ============================================================================
-- SECTION 17: DOMAIN 16 — COMPLIANCE, SUITABILITY & REGULATORY GOVERNANCE
--             (SCHEMA: compliance_suitability_and_regulatory_governance)
-- ============================================================================

-- 16.1 Suitability & Best Interest Review
CREATE TABLE IF NOT EXISTS compliance_suitability_and_regulatory_governance.suitability_and_best_interest_review (
    compliance_review_identifier                        VARCHAR(64)     NOT NULL,
    application_identifier                              VARCHAR(64)     NOT NULL,
    producer_identifier                                 VARCHAR(64)     NOT NULL,
    regulatory_framework                                VARCHAR(150)    NOT NULL,
    customer_risk_tolerance                             VARCHAR(100)    NOT NULL,
    customer_financial_objectives                       VARCHAR(150)    NOT NULL,
    customer_investment_time_horizon                    VARCHAR(100)    NOT NULL,
    existing_liquid_net_worth_amount                    NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    source_of_funds                                     VARCHAR(150)    NOT NULL,
    replacement_1035_surrender_penalty_incurred_amount  NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    replacement_benefit_comparison_score                VARCHAR(150)    NOT NULL,
    supervisory_principal_name                          VARCHAR(150)    NOT NULL,
    compliance_review_decision                          VARCHAR(120)    NOT NULL,
    approval_date                                       DATE            NULL,
    created_at                                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_suitability_and_best_interest_review PRIMARY KEY (compliance_review_identifier)
);
COMMENT ON TABLE compliance_suitability_and_regulatory_governance.suitability_and_best_interest_review IS 'Records supervisory compliance evaluation under SEC Reg BI, NAIC Model Reg #275, NY Reg 187, and ERISA PTE 2020-02 fiduciary standards.';

-- 16.2 Free-Look & Rescission Tracking
CREATE TABLE IF NOT EXISTS compliance_suitability_and_regulatory_governance.free_look_and_rescission_tracking (
    free_look_tracking_identifier       VARCHAR(64)     NOT NULL,
    policy_identifier                   VARCHAR(64)     NOT NULL,
    policy_delivery_date                DATE            NOT NULL,
    state_mandated_free_look_days       INTEGER         NOT NULL DEFAULT 10,
    free_look_expiration_date           DATE            NOT NULL,
    refund_basis_rule                   VARCHAR(150)    NOT NULL,
    free_look_exercised_indicator       VARCHAR(100)    NOT NULL,
    rescission_processed_date           DATE            NULL,
    created_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_free_look_and_rescission_tracking PRIMARY KEY (free_look_tracking_identifier),
    CONSTRAINT uq_free_look_policy UNIQUE (policy_identifier),
    CONSTRAINT chk_free_look_dates CHECK (free_look_expiration_date >= policy_delivery_date)
);
COMMENT ON TABLE compliance_suitability_and_regulatory_governance.free_look_and_rescission_tracking IS 'Monitors the statutory post-delivery free-look window during which a policyholder may cancel a newly issued contract without surrender penalty.';

-- 16.3 Unclaimed Property & Escheatment Case
CREATE TABLE IF NOT EXISTS compliance_suitability_and_regulatory_governance.unclaimed_property_and_escheatment_case (
    escheatment_case_identifier                 VARCHAR(64)     NOT NULL,
    policy_identifier                           VARCHAR(64)     NOT NULL,
    trigger_source                              VARCHAR(150)    NOT NULL,
    date_of_first_dormancy_or_dmf_match         DATE            NOT NULL,
    good_faith_outreach_due_diligence_status    VARCHAR(150)    NOT NULL,
    state_dormancy_period_years                 INTEGER         NOT NULL DEFAULT 3,
    target_escheatment_state_jurisdiction       VARCHAR(10)     NOT NULL,
    escheatable_amount                          NUMERIC(18,2)   NOT NULL DEFAULT 0.00,
    state_remittance_filing_date                DATE            NULL,
    case_status                                 VARCHAR(120)    NOT NULL,
    created_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                                  TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_unclaimed_property_escheatment_case PRIMARY KEY (escheatment_case_identifier)
);
COMMENT ON TABLE compliance_suitability_and_regulatory_governance.unclaimed_property_and_escheatment_case IS 'Tracks policies flagged via Death Master File (DMF) matches, returned mail (RPO), or uncashed checks through due diligence and state escheatment.';


-- ============================================================================
-- SECTION 18: FOREIGN KEY CONSTRAINTS (INTRA-DOMAIN & CROSS-DOMAIN)
-- ============================================================================

-- Domain 1: Product Foreign Keys
ALTER TABLE product.product
    ADD CONSTRAINT fk_product_product_line
    FOREIGN KEY (product_line_identifier)
    REFERENCES product.product_line (product_line_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE product.product_state_filing_and_availability
    ADD CONSTRAINT fk_product_state_filing_product
    FOREIGN KEY (product_identifier)
    REFERENCES product.product (product_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE product.product_crediting_and_liquidity_rule
    ADD CONSTRAINT fk_product_crediting_rule_product
    FOREIGN KEY (product_identifier)
    REFERENCES product.product (product_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE product.product_eligible_investment_fund
    ADD CONSTRAINT fk_pef_product
    FOREIGN KEY (product_identifier)
    REFERENCES product.product (product_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_pef_investment_fund
    FOREIGN KEY (investment_fund_identifier)
    REFERENCES fund.investment_fund (investment_fund_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE product.product_eligible_rider
    ADD CONSTRAINT fk_per_product
    FOREIGN KEY (product_identifier)
    REFERENCES product.product (product_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_per_rider_product
    FOREIGN KEY (rider_product_identifier)
    REFERENCES riders.rider_product_definition (rider_product_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

-- Domain 2: Policy Foreign Keys
ALTER TABLE policy.policy
    ADD CONSTRAINT fk_policy_product
    FOREIGN KEY (product_identifier)
    REFERENCES product.product (product_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_policy_institutional_plan
    FOREIGN KEY (institutional_plan_identifier)
    REFERENCES institutional_plan_and_employer_sponsor.institutional_retirement_plan (institutional_plan_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_policy_application
    FOREIGN KEY (application_identifier)
    REFERENCES underwriting_and_new_business.application (application_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE policy.policy_coverage_segment
    ADD CONSTRAINT fk_coverage_segment_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE policy.policy_vintage_bucket_balance
    ADD CONSTRAINT fk_vintage_bucket_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_vintage_bucket_crediting_decl
    FOREIGN KEY (crediting_rate_declaration_identifier)
    REFERENCES finance.general_account_crediting_rate_declaration (crediting_rate_declaration_identifier)
    ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE policy.policy_loan
    ADD CONSTRAINT fk_policy_loan_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

-- Domain 3: Riders Foreign Keys
ALTER TABLE riders.policy_rider_coverage
    ADD CONSTRAINT fk_policy_rider_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_policy_rider_definition
    FOREIGN KEY (rider_product_identifier)
    REFERENCES riders.rider_product_definition (rider_product_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE riders.rider_benefit_base_valuation
    ADD CONSTRAINT fk_rider_valuation_policy_rider
    FOREIGN KEY (policy_rider_identifier)
    REFERENCES riders.policy_rider_coverage (policy_rider_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE;

-- Domain 4: Fund Foreign Keys
ALTER TABLE fund.fund_unit_price
    ADD CONSTRAINT fk_fund_unit_price_fund
    FOREIGN KEY (investment_fund_identifier)
    REFERENCES fund.investment_fund (investment_fund_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE fund.policy_fund_allocation_election
    ADD CONSTRAINT fk_pfae_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_pfae_investment_fund
    FOREIGN KEY (investment_fund_identifier)
    REFERENCES fund.investment_fund (investment_fund_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE fund.policy_valuation_account
    ADD CONSTRAINT fk_pva_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_pva_investment_fund
    FOREIGN KEY (investment_fund_identifier)
    REFERENCES fund.investment_fund (investment_fund_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_pva_vintage_bucket
    FOREIGN KEY (policy_vintage_bucket_identifier)
    REFERENCES policy.policy_vintage_bucket_balance (policy_vintage_bucket_identifier)
    ON UPDATE CASCADE ON DELETE SET NULL;

-- Domain 5: Transactions Foreign Keys
ALTER TABLE transactions.financial_transaction
    ADD CONSTRAINT fk_fin_tx_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_fin_tx_remittance_batch
    FOREIGN KEY (remittance_batch_identifier)
    REFERENCES billing_remittance_and_tax_reporting.institutional_payroll_remittance_batch (remittance_batch_identifier)
    ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE transactions.transaction_fund_allocation_detail
    ADD CONSTRAINT fk_tfad_financial_transaction
    FOREIGN KEY (financial_transaction_identifier)
    REFERENCES transactions.financial_transaction (financial_transaction_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_tfad_holding_account
    FOREIGN KEY (holding_account_identifier)
    REFERENCES fund.policy_valuation_account (holding_account_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_tfad_investment_fund
    FOREIGN KEY (investment_fund_identifier)
    REFERENCES fund.investment_fund (investment_fund_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE transactions.non_financial_service_transaction
    ADD CONSTRAINT fk_nfst_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE;

-- Domain 6: Reinsurance Foreign Keys
ALTER TABLE reinsurance.reinsurance_treaty_participant
    ADD CONSTRAINT fk_rtp_treaty
    FOREIGN KEY (reinsurance_treaty_identifier)
    REFERENCES reinsurance.reinsurance_treaty (reinsurance_treaty_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_rtp_counterparty
    FOREIGN KEY (reinsurer_counterparty_identifier)
    REFERENCES reinsurance.reinsurer_counterparty (reinsurer_counterparty_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE reinsurance.reinsured_policy_cession
    ADD CONSTRAINT fk_rpc_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_rpc_treaty
    FOREIGN KEY (reinsurance_treaty_identifier)
    REFERENCES reinsurance.reinsurance_treaty (reinsurance_treaty_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE reinsurance.reinsurance_claim_recovery
    ADD CONSTRAINT fk_rcr_cession
    FOREIGN KEY (cession_identifier)
    REFERENCES reinsurance.reinsured_policy_cession (cession_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_rcr_claim
    FOREIGN KEY (claim_identifier)
    REFERENCES claims_annuitization_and_benefit_payouts.claim_and_benefit_settlement (claim_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

-- Domain 7: Finance Foreign Keys
ALTER TABLE finance.sub_ledger_journal_entry
    ADD CONSTRAINT fk_slje_accounting_period
    FOREIGN KEY (accounting_period_identifier)
    REFERENCES finance.accounting_period (accounting_period_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_slje_financial_transaction
    FOREIGN KEY (financial_transaction_identifier)
    REFERENCES transactions.financial_transaction (financial_transaction_identifier)
    ON UPDATE CASCADE ON DELETE SET NULL,
    ADD CONSTRAINT fk_slje_actuarial_reserve
    FOREIGN KEY (actuarial_valuation_reserve_identifier)
    REFERENCES actuarial.actuarial_valuation_reserve (actuarial_valuation_reserve_identifier)
    ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE finance.journal_entry_line
    ADD CONSTRAINT fk_jel_journal_entry
    FOREIGN KEY (sub_ledger_journal_entry_identifier)
    REFERENCES finance.sub_ledger_journal_entry (sub_ledger_journal_entry_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_jel_gl_account
    FOREIGN KEY (general_ledger_account_identifier)
    REFERENCES finance.general_ledger_account (general_ledger_account_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_jel_ldti_cohort
    FOREIGN KEY (ldti_cohort_identifier)
    REFERENCES actuarial.ldti_valuation_cohort (ldti_cohort_identifier)
    ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE finance.general_account_crediting_rate_declaration
    ADD CONSTRAINT fk_gacrd_product
    FOREIGN KEY (product_identifier)
    REFERENCES product.product (product_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

-- Domain 8: Experience Studies Foreign Keys
ALTER TABLE experience_studies.experience_exposure_and_decrement_cohort
    ADD CONSTRAINT fk_eedc_experience_study
    FOREIGN KEY (experience_study_identifier)
    REFERENCES experience_studies.experience_study (experience_study_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE experience_studies.experience_study_policy_observation
    ADD CONSTRAINT fk_espo_experience_study
    FOREIGN KEY (experience_study_identifier)
    REFERENCES experience_studies.experience_study (experience_study_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_espo_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_espo_claim
    FOREIGN KEY (claim_identifier)
    REFERENCES claims_annuitization_and_benefit_payouts.claim_and_benefit_settlement (claim_identifier)
    ON UPDATE CASCADE ON DELETE SET NULL;

-- Domain 9: Actuarial Foreign Keys
ALTER TABLE actuarial.actuarial_assumption_set
    ADD CONSTRAINT fk_aas_experience_study
    FOREIGN KEY (experience_study_identifier)
    REFERENCES experience_studies.experience_study (experience_study_identifier)
    ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE actuarial.actuarial_valuation_reserve
    ADD CONSTRAINT fk_avr_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_avr_assumption_set
    FOREIGN KEY (actuarial_assumption_set_identifier)
    REFERENCES actuarial.actuarial_assumption_set (actuarial_assumption_set_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_avr_ldti_cohort
    FOREIGN KEY (ldti_cohort_identifier)
    REFERENCES actuarial.ldti_valuation_cohort (ldti_cohort_identifier)
    ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE actuarial.actuarial_cash_flow_projection
    ADD CONSTRAINT fk_acfp_assumption_set
    FOREIGN KEY (actuarial_assumption_set_identifier)
    REFERENCES actuarial.actuarial_assumption_set (actuarial_assumption_set_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_acfp_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE SET NULL;

-- Domain 10: Agent & Agency Foreign Keys
ALTER TABLE agent_and_agency.producer_advisor
    ADD CONSTRAINT fk_producer_agency
    FOREIGN KEY (agency_identifier)
    REFERENCES agent_and_agency.agency (agency_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE agent_and_agency.producer_license_and_carrier_appointment
    ADD CONSTRAINT fk_plca_producer
    FOREIGN KEY (producer_identifier)
    REFERENCES agent_and_agency.producer_advisor (producer_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE agent_and_agency.policy_producer_assignment
    ADD CONSTRAINT fk_ppa_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_ppa_producer
    FOREIGN KEY (producer_identifier)
    REFERENCES agent_and_agency.producer_advisor (producer_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_ppa_agency
    FOREIGN KEY (agency_identifier)
    REFERENCES agent_and_agency.agency (agency_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE agent_and_agency.compensation_schedule_and_commission_statement
    ADD CONSTRAINT fk_cscs_policy_producer_assignment
    FOREIGN KEY (policy_producer_assignment_identifier)
    REFERENCES agent_and_agency.policy_producer_assignment (policy_producer_assignment_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_cscs_financial_transaction
    FOREIGN KEY (financial_transaction_identifier)
    REFERENCES transactions.financial_transaction (financial_transaction_identifier)
    ON UPDATE CASCADE ON DELETE SET NULL;

-- Domain 11: Party, Customer & Household Foreign Keys
ALTER TABLE party_customer_and_household.party_contact_and_address_profile
    ADD CONSTRAINT fk_pcap_party
    FOREIGN KEY (party_identifier)
    REFERENCES party_customer_and_household.party (party_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE party_customer_and_household.household
    ADD CONSTRAINT fk_household_primary_head_party
    FOREIGN KEY (primary_household_head_party_identifier)
    REFERENCES party_customer_and_household.party (party_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE party_customer_and_household.household_member_assignment
    ADD CONSTRAINT fk_hma_household
    FOREIGN KEY (household_identifier)
    REFERENCES party_customer_and_household.household (household_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_hma_party
    FOREIGN KEY (party_identifier)
    REFERENCES party_customer_and_household.party (party_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE party_customer_and_household.policy_party_role
    ADD CONSTRAINT fk_ppr_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_ppr_party
    FOREIGN KEY (party_identifier)
    REFERENCES party_customer_and_household.party (party_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

-- Domain 12: Institutional Plan & Employer Sponsor Foreign Keys
ALTER TABLE institutional_plan_and_employer_sponsor.employer_sponsor_organization
    ADD CONSTRAINT fk_eso_party
    FOREIGN KEY (party_identifier)
    REFERENCES party_customer_and_household.party (party_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE institutional_plan_and_employer_sponsor.institutional_retirement_plan
    ADD CONSTRAINT fk_irp_employer_sponsor
    FOREIGN KEY (employer_sponsor_identifier)
    REFERENCES institutional_plan_and_employer_sponsor.employer_sponsor_organization (employer_sponsor_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_irp_qdia_fund
    FOREIGN KEY (default_investment_option_qdia_fund_id)
    REFERENCES fund.investment_fund (investment_fund_identifier)
    ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE institutional_plan_and_employer_sponsor.plan_eligibility_and_contribution_rule
    ADD CONSTRAINT fk_pecr_institutional_plan
    FOREIGN KEY (institutional_plan_identifier)
    REFERENCES institutional_plan_and_employer_sponsor.institutional_retirement_plan (institutional_plan_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE institutional_plan_and_employer_sponsor.plan_vesting_schedule
    ADD CONSTRAINT fk_pvs_institutional_plan
    FOREIGN KEY (institutional_plan_identifier)
    REFERENCES institutional_plan_and_employer_sponsor.institutional_retirement_plan (institutional_plan_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE;

-- Domain 13: Underwriting & New Business Foreign Keys
ALTER TABLE underwriting_and_new_business.quote_and_policy_illustration
    ADD CONSTRAINT fk_qpi_product
    FOREIGN KEY (product_identifier)
    REFERENCES product.product (product_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_qpi_producer
    FOREIGN KEY (producer_identifier)
    REFERENCES agent_and_agency.producer_advisor (producer_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE underwriting_and_new_business.application
    ADD CONSTRAINT fk_app_illustration
    FOREIGN KEY (illustration_identifier)
    REFERENCES underwriting_and_new_business.quote_and_policy_illustration (illustration_identifier)
    ON UPDATE CASCADE ON DELETE SET NULL,
    ADD CONSTRAINT fk_app_product
    FOREIGN KEY (product_identifier)
    REFERENCES product.product (product_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_app_applicant_party
    FOREIGN KEY (applicant_party_identifier)
    REFERENCES party_customer_and_household.party (party_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE underwriting_and_new_business.underwriting_case_and_risk_decision
    ADD CONSTRAINT fk_ucrd_application
    FOREIGN KEY (application_identifier)
    REFERENCES underwriting_and_new_business.application (application_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_ucrd_insured_party
    FOREIGN KEY (insured_party_identifier)
    REFERENCES party_customer_and_household.party (party_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE underwriting_and_new_business.medical_and_mortality_requirement
    ADD CONSTRAINT fk_mmr_underwriting_case
    FOREIGN KEY (underwriting_case_identifier)
    REFERENCES underwriting_and_new_business.underwriting_case_and_risk_decision (underwriting_case_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE;

-- Domain 14: Claims, Annuitization & Benefit Payouts Foreign Keys
ALTER TABLE claims_annuitization_and_benefit_payouts.annuitization_payout_schedule
    ADD CONSTRAINT fk_aps_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_aps_primary_annuitant
    FOREIGN KEY (primary_annuitant_party_identifier)
    REFERENCES party_customer_and_household.party (party_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_aps_joint_annuitant
    FOREIGN KEY (joint_survivor_annuitant_party_identifier)
    REFERENCES party_customer_and_household.party (party_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE claims_annuitization_and_benefit_payouts.required_minimum_distribution_schedule
    ADD CONSTRAINT fk_rmd_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE claims_annuitization_and_benefit_payouts.claim_and_benefit_settlement
    ADD CONSTRAINT fk_cbs_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_cbs_insured_annuitant_party
    FOREIGN KEY (insured_or_annuitant_party_identifier)
    REFERENCES party_customer_and_household.party (party_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE claims_annuitization_and_benefit_payouts.beneficiary_claim_payout_election
    ADD CONSTRAINT fk_bcpe_claim
    FOREIGN KEY (claim_identifier)
    REFERENCES claims_annuitization_and_benefit_payouts.claim_and_benefit_settlement (claim_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_bcpe_beneficiary_party
    FOREIGN KEY (beneficiary_party_identifier)
    REFERENCES party_customer_and_household.party (party_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

-- Domain 15: Billing, Remittance & Tax Reporting Foreign Keys
ALTER TABLE billing_remittance_and_tax_reporting.institutional_payroll_remittance_batch
    ADD CONSTRAINT fk_iprb_institutional_plan
    FOREIGN KEY (institutional_plan_identifier)
    REFERENCES institutional_plan_and_employer_sponsor.institutional_retirement_plan (institutional_plan_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE billing_remittance_and_tax_reporting.billing_and_tax_withholding_schedule
    ADD CONSTRAINT fk_btws_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE billing_remittance_and_tax_reporting.tax_reporting_statement
    ADD CONSTRAINT fk_trs_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_trs_recipient_party
    FOREIGN KEY (recipient_party_identifier)
    REFERENCES party_customer_and_household.party (party_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

-- Domain 16: Compliance, Suitability & Regulatory Governance Foreign Keys
ALTER TABLE compliance_suitability_and_regulatory_governance.suitability_and_best_interest_review
    ADD CONSTRAINT fk_sbir_application
    FOREIGN KEY (application_identifier)
    REFERENCES underwriting_and_new_business.application (application_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_sbir_producer
    FOREIGN KEY (producer_identifier)
    REFERENCES agent_and_agency.producer_advisor (producer_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE compliance_suitability_and_regulatory_governance.free_look_and_rescission_tracking
    ADD CONSTRAINT fk_flrt_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE compliance_suitability_and_regulatory_governance.unclaimed_property_and_escheatment_case
    ADD CONSTRAINT fk_upec_policy
    FOREIGN KEY (policy_identifier)
    REFERENCES policy.policy (policy_identifier)
    ON UPDATE CASCADE ON DELETE RESTRICT;


-- ============================================================================
-- SECTION 19: PERFORMANCE INDEXES (FK INDEXES, COMPOSITE & QUERY INDEXES)
-- ============================================================================

-- Domain 1: Product Indexes
CREATE INDEX IF NOT EXISTS idx_product_line_id ON product.product (product_line_identifier);
CREATE INDEX IF NOT EXISTS idx_product_category_status ON product.product (product_category, effective_launch_date);
CREATE INDEX IF NOT EXISTS idx_psf_product_state ON product.product_state_filing_and_availability (product_identifier, jurisdiction_state_name);
CREATE INDEX IF NOT EXISTS idx_pclr_product_id ON product.product_crediting_and_liquidity_rule (product_identifier);
CREATE INDEX IF NOT EXISTS idx_pef_fund_id ON product.product_eligible_investment_fund (investment_fund_identifier);
CREATE INDEX IF NOT EXISTS idx_per_rider_id ON product.product_eligible_rider (rider_product_identifier);

-- Domain 2: Policy Indexes
CREATE INDEX IF NOT EXISTS idx_policy_product_id ON policy.policy (product_identifier);
CREATE INDEX IF NOT EXISTS idx_policy_inst_plan_id ON policy.policy (institutional_plan_identifier);
CREATE INDEX IF NOT EXISTS idx_policy_application_id ON policy.policy (application_identifier);
CREATE INDEX IF NOT EXISTS idx_policy_status_issue_date ON policy.policy (policy_status, contract_issue_date);
CREATE INDEX IF NOT EXISTS idx_policy_certificate_num ON policy.policy (contract_certificate_number);
CREATE INDEX IF NOT EXISTS idx_pcs_policy_id ON policy.policy_coverage_segment (policy_identifier);
CREATE INDEX IF NOT EXISTS idx_pvbb_policy_vintage ON policy.policy_vintage_bucket_balance (policy_identifier, vintage_period_identifier);
CREATE INDEX IF NOT EXISTS idx_pvbb_crd_id ON policy.policy_vintage_bucket_balance (crediting_rate_declaration_identifier);
CREATE INDEX IF NOT EXISTS idx_policy_loan_policy_status ON policy.policy_loan (policy_identifier, loan_default_status);

-- Domain 3: Riders Indexes
CREATE INDEX IF NOT EXISTS idx_prc_policy_status ON riders.policy_rider_coverage (policy_identifier, rider_status);
CREATE INDEX IF NOT EXISTS idx_prc_rider_product_id ON riders.policy_rider_coverage (rider_product_identifier);
CREATE INDEX IF NOT EXISTS idx_rbbv_policy_rider_date ON riders.rider_benefit_base_valuation (policy_rider_identifier, valuation_date DESC);

-- Domain 4: Fund Indexes
CREATE INDEX IF NOT EXISTS idx_fund_asset_class ON fund.investment_fund (asset_class, account_structure_type);
CREATE INDEX IF NOT EXISTS idx_fup_fund_val_date ON fund.fund_unit_price (investment_fund_identifier, valuation_date DESC);
CREATE INDEX IF NOT EXISTS idx_pfae_policy_type ON fund.policy_fund_allocation_election (policy_identifier, allocation_type);
CREATE INDEX IF NOT EXISTS idx_pfae_fund_id ON fund.policy_fund_allocation_election (investment_fund_identifier);
CREATE INDEX IF NOT EXISTS idx_pva_policy_fund ON fund.policy_valuation_account (policy_identifier, investment_fund_identifier);
CREATE INDEX IF NOT EXISTS idx_pva_vintage_bucket_id ON fund.policy_valuation_account (policy_vintage_bucket_identifier);

-- Domain 5: Transactions Indexes
CREATE INDEX IF NOT EXISTS idx_ftx_policy_eff_date ON transactions.financial_transaction (policy_identifier, transaction_effective_date DESC);
CREATE INDEX IF NOT EXISTS idx_ftx_type_proc_date ON transactions.financial_transaction (transaction_type, transaction_processing_date DESC);
CREATE INDEX IF NOT EXISTS idx_ftx_remittance_batch_id ON transactions.financial_transaction (remittance_batch_identifier);
CREATE INDEX IF NOT EXISTS idx_tfad_fin_tx_id ON transactions.transaction_fund_allocation_detail (financial_transaction_identifier);
CREATE INDEX IF NOT EXISTS idx_tfad_holding_acct_id ON transactions.transaction_fund_allocation_detail (holding_account_identifier);
CREATE INDEX IF NOT EXISTS idx_tfad_fund_id ON transactions.transaction_fund_allocation_detail (investment_fund_identifier);
CREATE INDEX IF NOT EXISTS idx_nfst_policy_eff_date ON transactions.non_financial_service_transaction (policy_identifier, effective_date DESC);

-- Domain 6: Reinsurance Indexes
CREATE INDEX IF NOT EXISTS idx_rtp_treaty_id ON reinsurance.reinsurance_treaty_participant (reinsurance_treaty_identifier);
CREATE INDEX IF NOT EXISTS idx_rtp_counterparty_id ON reinsurance.reinsurance_treaty_participant (reinsurer_counterparty_identifier);
CREATE INDEX IF NOT EXISTS idx_rpc_policy_eff_date ON reinsurance.reinsured_policy_cession (policy_identifier, cession_effective_date DESC);
CREATE INDEX IF NOT EXISTS idx_rpc_treaty_id ON reinsurance.reinsured_policy_cession (reinsurance_treaty_identifier);
CREATE INDEX IF NOT EXISTS idx_rcr_cession_id ON reinsurance.reinsurance_claim_recovery (cession_identifier);
CREATE INDEX IF NOT EXISTS idx_rcr_claim_status ON reinsurance.reinsurance_claim_recovery (claim_identifier, recovery_settlement_status);

-- Domain 7: Finance Indexes
CREATE INDEX IF NOT EXISTS idx_slje_period_basis ON finance.sub_ledger_journal_entry (accounting_period_identifier, accounting_basis);
CREATE INDEX IF NOT EXISTS idx_slje_fin_tx_id ON finance.sub_ledger_journal_entry (financial_transaction_identifier);
CREATE INDEX IF NOT EXISTS idx_slje_act_res_id ON finance.sub_ledger_journal_entry (actuarial_valuation_reserve_identifier);
CREATE INDEX IF NOT EXISTS idx_jel_slje_id ON finance.journal_entry_line (sub_ledger_journal_entry_identifier);
CREATE INDEX IF NOT EXISTS idx_jel_gl_acct_id ON finance.journal_entry_line (general_ledger_account_identifier);
CREATE INDEX IF NOT EXISTS idx_jel_ldti_cohort_id ON finance.journal_entry_line (ldti_cohort_identifier);
CREATE INDEX IF NOT EXISTS idx_gacrd_product_vintage ON finance.general_account_crediting_rate_declaration (product_identifier, vintage_period_identifier, declaration_effective_date DESC);

-- Domain 8: Experience Studies Indexes
CREATE INDEX IF NOT EXISTS idx_eedc_study_category ON experience_studies.experience_exposure_and_decrement_cohort (experience_study_identifier, product_category, attained_age_band);
CREATE INDEX IF NOT EXISTS idx_espo_study_policy ON experience_studies.experience_study_policy_observation (experience_study_identifier, policy_identifier);
CREATE INDEX IF NOT EXISTS idx_espo_claim_id ON experience_studies.experience_study_policy_observation (claim_identifier);

-- Domain 9: Actuarial Indexes
CREATE INDEX IF NOT EXISTS idx_aas_exp_study_id ON actuarial.actuarial_assumption_set (experience_study_identifier);
CREATE INDEX IF NOT EXISTS idx_avr_policy_val_date ON actuarial.actuarial_valuation_reserve (policy_identifier, valuation_date DESC);
CREATE INDEX IF NOT EXISTS idx_avr_assumption_set_id ON actuarial.actuarial_valuation_reserve (actuarial_assumption_set_identifier);
CREATE INDEX IF NOT EXISTS idx_avr_ldti_cohort_id ON actuarial.actuarial_valuation_reserve (ldti_cohort_identifier);
CREATE INDEX IF NOT EXISTS idx_acfp_run_scenario ON actuarial.actuarial_cash_flow_projection (projection_run_identifier, economic_scenario_number);
CREATE INDEX IF NOT EXISTS idx_acfp_policy_id ON actuarial.actuarial_cash_flow_projection (policy_identifier);

-- Domain 10: Agent & Agency Indexes
CREATE INDEX IF NOT EXISTS idx_producer_agency_id ON agent_and_agency.producer_advisor (agency_identifier, active_status);
CREATE INDEX IF NOT EXISTS idx_plca_producer_state ON agent_and_agency.producer_license_and_carrier_appointment (producer_identifier, state_jurisdiction, carrier_appointment_status);
CREATE INDEX IF NOT EXISTS idx_ppa_policy_id ON agent_and_agency.policy_producer_assignment (policy_identifier);
CREATE INDEX IF NOT EXISTS idx_ppa_producer_id ON agent_and_agency.policy_producer_assignment (producer_identifier);
CREATE INDEX IF NOT EXISTS idx_ppa_agency_id ON agent_and_agency.policy_producer_assignment (agency_identifier);
CREATE INDEX IF NOT EXISTS idx_cscs_ppa_pay_date ON agent_and_agency.compensation_schedule_and_commission_statement (policy_producer_assignment_identifier, statement_payment_date DESC);
CREATE INDEX IF NOT EXISTS idx_cscs_fin_tx_id ON agent_and_agency.compensation_schedule_and_commission_statement (financial_transaction_identifier);

-- Domain 11: Party, Customer & Household Indexes
CREATE INDEX IF NOT EXISTS idx_party_name_dob ON party_customer_and_household.party (full_legal_name, date_of_birth);
CREATE INDEX IF NOT EXISTS idx_party_type_state ON party_customer_and_household.party (party_type, primary_residence_state);
CREATE INDEX IF NOT EXISTS idx_pcap_party_type ON party_customer_and_household.party_contact_and_address_profile (party_identifier, address_type);
CREATE INDEX IF NOT EXISTS idx_household_head_party ON party_customer_and_household.household (primary_household_head_party_identifier);
CREATE INDEX IF NOT EXISTS idx_hma_party_id ON party_customer_and_household.household_member_assignment (party_identifier);
CREATE INDEX IF NOT EXISTS idx_ppr_policy_role ON party_customer_and_household.policy_party_role (policy_identifier, role_type);
CREATE INDEX IF NOT EXISTS idx_ppr_party_role ON party_customer_and_household.policy_party_role (party_identifier, role_type);

-- Domain 12: Institutional Plan & Employer Sponsor Indexes
CREATE INDEX IF NOT EXISTS idx_eso_party_id ON institutional_plan_and_employer_sponsor.employer_sponsor_organization (party_identifier);
CREATE INDEX IF NOT EXISTS idx_irp_employer_sponsor ON institutional_plan_and_employer_sponsor.institutional_retirement_plan (employer_sponsor_identifier, plan_tax_code_type);
CREATE INDEX IF NOT EXISTS idx_irp_qdia_fund_id ON institutional_plan_and_employer_sponsor.institutional_retirement_plan (default_investment_option_qdia_fund_id);
CREATE INDEX IF NOT EXISTS idx_pecr_plan_id ON institutional_plan_and_employer_sponsor.plan_eligibility_and_contribution_rule (institutional_plan_identifier);
CREATE INDEX IF NOT EXISTS idx_pvs_plan_id ON institutional_plan_and_employer_sponsor.plan_vesting_schedule (institutional_plan_identifier);

-- Domain 13: Underwriting & New Business Indexes
CREATE INDEX IF NOT EXISTS idx_qpi_product_producer ON underwriting_and_new_business.quote_and_policy_illustration (product_identifier, producer_identifier);
CREATE INDEX IF NOT EXISTS idx_app_applicant_status ON underwriting_and_new_business.application (applicant_party_identifier, application_status);
CREATE INDEX IF NOT EXISTS idx_app_product_sub_date ON underwriting_and_new_business.application (product_identifier, submission_date DESC);
CREATE INDEX IF NOT EXISTS idx_ucrd_application_id ON underwriting_and_new_business.underwriting_case_and_risk_decision (application_identifier);
CREATE INDEX IF NOT EXISTS idx_ucrd_insured_party_id ON underwriting_and_new_business.underwriting_case_and_risk_decision (insured_party_identifier);
CREATE INDEX IF NOT EXISTS idx_mmr_uw_case_status ON underwriting_and_new_business.medical_and_mortality_requirement (underwriting_case_identifier, requirement_status);

-- Domain 14: Claims, Annuitization & Benefit Payouts Indexes
CREATE INDEX IF NOT EXISTS idx_aps_policy_id ON claims_annuitization_and_benefit_payouts.annuitization_payout_schedule (policy_identifier);
CREATE INDEX IF NOT EXISTS idx_aps_primary_annuitant ON claims_annuitization_and_benefit_payouts.annuitization_payout_schedule (primary_annuitant_party_identifier);
CREATE INDEX IF NOT EXISTS idx_rmd_policy_year ON claims_annuitization_and_benefit_payouts.required_minimum_distribution_schedule (policy_identifier, tax_calendar_year DESC);
CREATE INDEX IF NOT EXISTS idx_cbs_policy_status ON claims_annuitization_and_benefit_payouts.claim_and_benefit_settlement (policy_identifier, claim_status);
CREATE INDEX IF NOT EXISTS idx_cbs_insured_party ON claims_annuitization_and_benefit_payouts.claim_and_benefit_settlement (insured_or_annuitant_party_identifier);
CREATE INDEX IF NOT EXISTS idx_bcpe_claim_id ON claims_annuitization_and_benefit_payouts.beneficiary_claim_payout_election (claim_identifier);
CREATE INDEX IF NOT EXISTS idx_bcpe_beneficiary_party ON claims_annuitization_and_benefit_payouts.beneficiary_claim_payout_election (beneficiary_party_identifier);

-- Domain 15: Billing, Remittance & Tax Reporting Indexes
CREATE INDEX IF NOT EXISTS idx_iprb_plan_pay_date ON billing_remittance_and_tax_reporting.institutional_payroll_remittance_batch (institutional_plan_identifier, payroll_pay_period_end_date DESC);
CREATE INDEX IF NOT EXISTS idx_btws_policy_due_date ON billing_remittance_and_tax_reporting.billing_and_tax_withholding_schedule (policy_identifier, next_bill_due_date);
CREATE INDEX IF NOT EXISTS idx_trs_policy_tax_year ON billing_remittance_and_tax_reporting.tax_reporting_statement (policy_identifier, tax_year DESC, tax_form_type);
CREATE INDEX IF NOT EXISTS idx_trs_recipient_tax_year ON billing_remittance_and_tax_reporting.tax_reporting_statement (recipient_party_identifier, tax_year DESC);

-- Domain 16: Compliance, Suitability & Regulatory Governance Indexes
CREATE INDEX IF NOT EXISTS idx_sbir_application_id ON compliance_suitability_and_regulatory_governance.suitability_and_best_interest_review (application_identifier);
CREATE INDEX IF NOT EXISTS idx_sbir_producer_decision ON compliance_suitability_and_regulatory_governance.suitability_and_best_interest_review (producer_identifier, compliance_review_decision);
CREATE INDEX IF NOT EXISTS idx_flrt_policy_exp_date ON compliance_suitability_and_regulatory_governance.free_look_and_rescission_tracking (policy_identifier, free_look_expiration_date);
CREATE INDEX IF NOT EXISTS idx_upec_policy_status ON compliance_suitability_and_regulatory_governance.unclaimed_property_and_escheatment_case (policy_identifier, case_status);
CREATE INDEX IF NOT EXISTS idx_upec_state_status ON compliance_suitability_and_regulatory_governance.unclaimed_property_and_escheatment_case (target_escheatment_state_jurisdiction, case_status);

-- ============================================================================
-- END OF DDL SCRIPT
-- ============================================================================



