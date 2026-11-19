-- =============================================================
-- Migration 004: cust_relationship.customer_related_persons
-- Purpose: Family, dependents and the trusted contact person (TCP)
--          for each client. A related person may also be a customer
--          (related_customer_id), or just a name we store here.
--
-- Needs first: db/schemas/create_schemas.sql
--              db/functions/set_updated_at.sql
--              db/migrations/001_create_customers.sql
-- =============================================================

BEGIN;

CREATE TABLE IF NOT EXISTS cust_relationship.customer_related_persons
(
    related_person_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    customer_id bigint NOT NULL,
    related_customer_id bigint,
    relationship_type character varying(30) COLLATE pg_catalog."default" NOT NULL,
    first_name character varying(100) COLLATE pg_catalog."default",
    last_name character varying(100) COLLATE pg_catalog."default",
    date_of_birth date,
    phone character varying(20) COLLATE pg_catalog."default",
    email character varying(255) COLLATE pg_catalog."default",
    is_dependent boolean NOT NULL DEFAULT false,
    is_trusted_contact boolean NOT NULL DEFAULT false,
    tcp_consent_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    deleted_at timestamp with time zone,
    CONSTRAINT pk_customer_related_persons PRIMARY KEY (related_person_id),
    CONSTRAINT fk_customer_related_persons_customer FOREIGN KEY (customer_id)
        REFERENCES cust_relationship.customers (customer_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_customer_related_persons_related_customer FOREIGN KEY (related_customer_id)
        REFERENCES cust_relationship.customers (customer_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT chk_customer_related_persons_dob_not_future CHECK (date_of_birth <= CURRENT_DATE),
    CONSTRAINT chk_customer_related_persons_name_required CHECK (related_customer_id IS NOT NULL OR first_name IS NOT NULL AND last_name IS NOT NULL),
    CONSTRAINT chk_customer_related_persons_not_self CHECK (related_customer_id <> customer_id),
    CONSTRAINT chk_customer_related_persons_relationship_type
        CHECK (relationship_type IN ('spouse', 'common_law_partner', 'child', 'parent', 'sibling',
                                     'other_family', 'friend', 'lawyer', 'accountant', 'other')),
    CONSTRAINT chk_customer_related_persons_tcp_details CHECK (NOT is_trusted_contact OR tcp_consent_at IS NOT NULL AND phone IS NOT NULL)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS cust_relationship.customer_related_persons
    OWNER to campaign_admin;

COMMENT ON TABLE cust_relationship.customer_related_persons
    IS 'Family, dependents and trusted contact person for each client.';

COMMENT ON COLUMN cust_relationship.customer_related_persons.related_customer_id
    IS 'Set only when the related person is also a customer; then their details live in customers.';

COMMENT ON COLUMN cust_relationship.customer_related_persons.is_dependent
    IS 'true = this person relies on the client financially (young child, non-working spouse, supported parent).';

COMMENT ON COLUMN cust_relationship.customer_related_persons.tcp_consent_at
    IS 'When the client allowed the firm to contact this trusted contact. Required when is_trusted_contact.';
-- Index: idx_customer_related_persons_customer_id

-- DROP INDEX IF EXISTS cust_relationship.idx_customer_related_persons_customer_id;

CREATE INDEX IF NOT EXISTS idx_customer_related_persons_customer_id
    ON cust_relationship.customer_related_persons USING btree
    (customer_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_customer_related_persons_related_customer_id

-- DROP INDEX IF EXISTS cust_relationship.idx_customer_related_persons_related_customer_id;

CREATE INDEX IF NOT EXISTS idx_customer_related_persons_related_customer_id
    ON cust_relationship.customer_related_persons USING btree
    (related_customer_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: uq_customer_related_persons_one_tcp

-- DROP INDEX IF EXISTS cust_relationship.uq_customer_related_persons_one_tcp;

CREATE UNIQUE INDEX IF NOT EXISTS uq_customer_related_persons_one_tcp
    ON cust_relationship.customer_related_persons USING btree
    (customer_id ASC NULLS LAST)
    TABLESPACE pg_default
    WHERE is_trusted_contact AND deleted_at IS NULL;

-- Trigger: trg_customer_related_persons_set_updated_at

-- DROP TRIGGER IF EXISTS trg_customer_related_persons_set_updated_at ON cust_relationship.customer_related_persons;

CREATE OR REPLACE TRIGGER trg_customer_related_persons_set_updated_at
    BEFORE UPDATE 
    ON cust_relationship.customer_related_persons
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();


COMMIT;