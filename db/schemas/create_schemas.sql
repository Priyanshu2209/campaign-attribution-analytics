-- =============================================================
-- File:    db/schemas/create_schemas.sql
-- Project: CampaignLens (campaign-attribution-analytics)
-- Purpose: Create every schema used by the project.
--          Schemas group related tables (like folders) and make
--          permissions easier to manage later (grant per schema).
--
-- Run this FIRST, before any file in db/migrations/,
-- because tables are created inside these schemas.
--
-- Safe to run more than once: IF NOT EXISTS skips schemas
-- that already exist instead of raising an error.
-- =============================================================


-- -------------------------------------------------------------
-- 1. cust_relationship
--    Who the client is: visitors, leads and customers, plus
--    their details, family/trusted contact and consents.
--    Tables (planned): customers, customer_addresses,
--    customer_contacts, customer_related_persons,
--    customer_financial_profiles, customer_employment,
--    customer_identity_verifications, consents, communications,
--    corporate_details, corporate_owners
-- -------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS cust_relationship
    AUTHORIZATION campaign_admin;

COMMENT ON SCHEMA cust_relationship IS
    'Customer relationship data: visitors, leads, customers and their details (addresses, contacts, related persons, KYC, consent, communications).';


-- -------------------------------------------------------------
-- 2. marketing
--    The campaigns themselves and how people come into contact
--    with them.
--    Tables (planned): campaigns, channels, campaign_channels,
--    campaign_offers, campaign_touchpoints
-- -------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS marketing
    AUTHORIZATION campaign_admin;

COMMENT ON SCHEMA marketing IS
    'Marketing campaigns, channels, offers, budgets/spend and campaign touchpoints.';


-- -------------------------------------------------------------
-- 3. sales
--    The advisor-led side: advisors, which advisor serves which
--    client, and appointments.
--    Tables (planned): advisors, customer_advisor_assignments,
--    appointments, advisor_availability
-- -------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS sales
    AUTHORIZATION campaign_admin;

COMMENT ON SCHEMA sales IS
    'Advisors, client-advisor assignments and appointments.';


-- -------------------------------------------------------------
-- 4. wealth
--    Accounts and money: the client's accounts (TFSA, RRSP,
--    joint...), who holds them, what is invested in them and
--    every movement of money.
--    Tables (planned): investment_products, accounts,
--    account_holders, investments, payments, transactions
-- -------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS wealth
    AUTHORIZATION campaign_admin;

COMMENT ON SCHEMA wealth IS
    'Accounts, account holders, investment products, investments, payments and transactions.';


-- -------------------------------------------------------------
-- 5. reporting
--    Views only (no raw data). Analysts and Python read from
--    here, so they can get read-only access to this schema
--    without seeing the raw tables.
--    Views (planned): funnel, campaign ROI, channel ROI,
--    advisor performance, customer segments
-- -------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS reporting
    AUTHORIZATION campaign_admin;

COMMENT ON SCHEMA reporting IS
    'Reporting views for analysis: funnel, campaign and channel ROI, advisor performance, customer segments.';


-- -------------------------------------------------------------
-- 6. audit
--    History of changes, written automatically by triggers.
--    Kept separate so normal users can never edit the history.
--    Tables (planned): audit_log
-- -------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS audit
    AUTHORIZATION campaign_admin;

COMMENT ON SCHEMA audit IS
    'Audit trail: records of inserts, updates and deletes, written by triggers.';


-- -------------------------------------------------------------
-- Check: list the project schemas and their owners
-- -------------------------------------------------------------
SELECT schema_name, schema_owner
FROM information_schema.schemata
WHERE schema_name IN ('cust_relationship', 'marketing', 'sales', 'wealth', 'reporting', 'audit')
ORDER BY schema_name;
