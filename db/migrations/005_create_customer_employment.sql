-- =============================================================
-- Migration 005: Create cust_relationship.customer_employment
-- Purpose: Employment history for each customer (KYC / AML).
--          A job change = set end_date on the old row, then add a
--          new row. Current situation = end_date IS NULL.
--          Income is NOT stored here (only in financial profiles).
--
-- Needs first: db/schemas/create_schemas.sql
--              db/functions/set_updated_at.sql
--              db/migrations/001_create_customers.sql
--
-- Notes:
--   occupation    = job title, e.g. 'Registered Nurse'
--   employer_name = own business name when self_employed
--   industry      = sector, e.g. 'Healthcare'
--   end_date      = NULL means current job / status
--   Rules: end_date can't be before start_date;
--          unemployed / retired -> no employer_name;
--          employed / self_employed -> occupation required.
--   No unique index on current rows: a client can have two current jobs.
-- =============================================================

CREATE TABLE IF NOT EXISTS cust_relationship.customer_employment
(
    customer_employment_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
    customer_id bigint NOT NULL,
    employment_status character varying(20) NOT NULL,
    occupation character varying(100),
    employer_name character varying(200),
    industry character varying(100),
    start_date date NOT NULL,
    end_date date,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    deleted_at timestamp with time zone,
    CONSTRAINT pk_customer_employment PRIMARY KEY (customer_employment_id),
    CONSTRAINT fk_customer_employment_customer FOREIGN KEY (customer_id) REFERENCES cust_relationship.customers (customer_id),
    CONSTRAINT chk_customer_employment_status CHECK (employment_status IN ('employed', 'self_employed', 'unemployed', 'retired', 'student')),
    CONSTRAINT chk_customer_employment_dates CHECK (end_date >= start_date),
    CONSTRAINT chk_customer_employment_no_employer_when_not_working CHECK (employment_status NOT IN ('unemployed', 'retired') OR employer_name IS NULL),
    CONSTRAINT chk_customer_employment_occupation_when_working CHECK (employment_status NOT IN ('employed', 'self_employed') OR occupation IS NOT NULL)
);

ALTER TABLE IF EXISTS cust_relationship.customer_employment
    OWNER to campaign_admin;

COMMENT ON TABLE cust_relationship.customer_employment
    IS 'Employment history per customer. Current situation = end_date IS NULL and deleted_at IS NULL.';

COMMENT ON COLUMN cust_relationship.customer_employment.end_date
    IS 'Last day of this job or status. NULL = current. A job change closes this row and adds a new one.';

-- Index the foreign key (our rule: every FK is indexed)
CREATE INDEX IF NOT EXISTS idx_customer_employment_customer_id
    ON cust_relationship.customer_employment (customer_id);

-- Trigger: keep updated_at current on every UPDATE
CREATE OR REPLACE TRIGGER trg_customer_employment_set_updated_at
    BEFORE UPDATE
    ON cust_relationship.customer_employment
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();