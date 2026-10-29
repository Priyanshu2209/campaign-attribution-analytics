-- =============================================================
-- Migration 001: Create cust_relationship.customers
-- Purpose: One table for everyone the company knows about.
--          is_customer = false -> visitor / lead
--          is_customer = true  -> customer with an account
--          When a visitor converts, the SAME row is updated.
--
-- Needs first: db/schemas/create_schemas.sql
--              db/functions/set_updated_at.sql
-- Built with:  pgAdmin Create Table window (SQL tab copied here)
-- =============================================================

CREATE TABLE IF NOT EXISTS cust_relationship.customers
(
    customer_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    email character varying(255) NOT NULL,
    is_customer boolean NOT NULL DEFAULT False,
    customer_number character varying(20),
    customer_type character varying(20),
    date_of_birth date,
    kyc_status character varying(20),
    acquired_campaign_id bigint,
    first_seen_at timestamp with time zone NOT NULL DEFAULT now(),
    became_customer_at timestamp with time zone,
    tcp_declined_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    deleted_at timestamp with time zone,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_customer_number UNIQUE (customer_number),
    CONSTRAINT chk_customers_customer_type CHECK (customer_type IN ('individual', 'corporate')),
    CONSTRAINT chk_customers_kyc_status CHECK (kyc_status IN ('pending', 'verified', 'expired', 'rejected')),
    CONSTRAINT chk_customers_customer_fields_required CHECK (NOT is_customer OR (customer_number IS NOT NULL AND customer_type IS NOT NULL AND kyc_status IS NOT NULL AND became_customer_at IS NOT NULL)),
    CONSTRAINT chk_customers_visitor_fields_empty CHECK (is_customer OR (customer_number IS NULL AND kyc_status IS NULL AND became_customer_at IS NULL)),
    CONSTRAINT chk_customers_individual_dob CHECK (NOT (is_customer AND customer_type = 'individual') OR date_of_birth IS NOT NULL),
    CONSTRAINT chk_customers_dob_not_future CHECK (date_of_birth <= CURRENT_DATE),
    CONSTRAINT chk_customers_became_after_first_seen CHECK (became_customer_at >= first_seen_at),
    CONSTRAINT chk_customers_tcp_declined_only_customers CHECK (tcp_declined_at IS NULL OR is_customer)
);

ALTER TABLE IF EXISTS cust_relationship.customers
    OWNER to campaign_admin;

COMMENT ON TABLE cust_relationship.customers
    IS 'Everyone the company knows: visitors/leads (is_customer = false) and customers (is_customer = true).';

-- Trigger: keep updated_at current on every UPDATE
CREATE OR REPLACE TRIGGER trg_customers_set_updated_at
    BEFORE UPDATE
    ON cust_relationship.customers
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- Email unique, ignoring capitals (John@Mail.com = john@mail.com)
CREATE UNIQUE INDEX IF NOT EXISTS uq_customers_email_lower
    ON cust_relationship.customers (lower(email));

-- Future foreign key column: speeds up "customers per campaign"
CREATE INDEX IF NOT EXISTS idx_customers_acquired_campaign_id
    ON cust_relationship.customers (acquired_campaign_id);
