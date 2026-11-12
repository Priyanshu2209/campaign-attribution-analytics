-- =============================================================
-- Migration 003: cust_relationship.customer_contacts
-- Purpose: All phone numbers and extra emails for each customer.
--          customers.email stays the main email; every phone
--          number lives here (customers has no phone column).
--
-- Needs first: db/schemas/create_schemas.sql
--              db/functions/set_updated_at.sql
--              db/migrations/001_create_customers.sql
-- =============================================================


CREATE TABLE cust_relationship.customer_contacts
(
    customer_contact_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
    customer_id bigint NOT NULL,
    contact_type character varying(20) NOT NULL,
    contact_number character varying(255) NOT NULL,
    is_primary boolean NOT NULL DEFAULT false,
    best_time_to_contact character varying(50),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    deleted_at timestamp with time zone,
    CONSTRAINT pk_customer_contacts PRIMARY KEY (customer_contact_id),
    CONSTRAINT fk_customer_contacts_customer FOREIGN KEY (customer_id)
        REFERENCES cust_relationship.customers (customer_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    CONSTRAINT chk_customer_contacts_contact_type CHECK (contact_type IN ('mobile', 'home_phone', 'work_phone', 'email')) NOT VALID
);

ALTER TABLE IF EXISTS cust_relationship.customer_contacts
    OWNER to campaign_admin;

COMMENT ON TABLE cust_relationship.customer_contacts
    IS 'All phone numbers and extra emails for each customer.';

-- Index the foreign key (our rule: every FK is indexed)
CREATE INDEX IF NOT EXISTS idx_customer_contacts_customer_id
    ON cust_relationship.customer_contacts (customer_id);

-- Only ONE primary contact per type per customer
CREATE UNIQUE INDEX IF NOT EXISTS uq_customer_contacts_one_primary_per_type
    ON cust_relationship.customer_contacts (customer_id, contact_type)
    WHERE is_primary AND deleted_at IS NULL;

-- Keep updated_at current on every UPDATE
CREATE OR REPLACE TRIGGER trg_customer_contacts_set_updated_at
    BEFORE UPDATE ON cust_relationship.customer_contacts
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

COMMIT;