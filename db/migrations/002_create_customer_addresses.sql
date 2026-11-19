-- Table: cust_relationship.customer_addresses

-- DROP TABLE IF EXISTS cust_relationship.customer_addresses;

CREATE TABLE IF NOT EXISTS cust_relationship.customer_addresses
(
    customer_address_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    customer_id bigint NOT NULL,
    address_type character varying(20) COLLATE pg_catalog."default" NOT NULL,
    unit_number character varying(10) COLLATE pg_catalog."default",
    address_line1 character varying(200) COLLATE pg_catalog."default" NOT NULL,
    address_line2 character varying(200) COLLATE pg_catalog."default",
    city character varying(100) COLLATE pg_catalog."default" NOT NULL,
    province character(2) COLLATE pg_catalog."default" NOT NULL,
    postal_code character(7) COLLATE pg_catalog."default" NOT NULL,
    lived_from date NOT NULL DEFAULT CURRENT_DATE,
    lived_until date,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    deleted_at timestamp with time zone,
    CONSTRAINT pk_customer_addresses PRIMARY KEY (customer_address_id),
    CONSTRAINT fk_customer_addresses_customer FOREIGN KEY (customer_id)
        REFERENCES cust_relationship.customers (customer_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT chk_customer_addresses_address_type CHECK (address_type::text = ANY (ARRAY['residential'::character varying, 'mailing'::character varying, 'business'::character varying]::text[])),
    CONSTRAINT chk_customer_addresses_lived_dates CHECK (lived_until >= lived_from),
    CONSTRAINT chk_customer_addresses_postal_code CHECK (postal_code ~ '^[A-Z][0-9][A-Z] [0-9][A-Z][0-9]$'::text),
    CONSTRAINT chk_customer_addresses_province CHECK (province = ANY (ARRAY['AB'::bpchar, 'BC'::bpchar, 'MB'::bpchar, 'NB'::bpchar, 'NL'::bpchar, 'NS'::bpchar, 'NT'::bpchar, 'NU'::bpchar, 'ON'::bpchar, 'PE'::bpchar, 'QC'::bpchar, 'SK'::bpchar, 'YT'::bpchar]))
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS cust_relationship.customer_addresses
    OWNER to campaign_admin;

COMMENT ON TABLE cust_relationship.customer_addresses
    IS 'Address history per customer. Current address = lived_until IS NULL and deleted_at IS NULL.';

COMMENT ON COLUMN cust_relationship.customer_addresses.lived_from
    IS 'Real-world move-in date (not the date it was entered).';

COMMENT ON COLUMN cust_relationship.customer_addresses.lived_until
    IS 'Real-world last day at this address. NULL = current address.';

COMMENT ON COLUMN cust_relationship.customer_addresses.deleted_at
    IS 'Soft delete, only for rows entered by mistake. A move uses lived_until instead.';
-- Index: idx_customer_addresses_customer_id

-- DROP INDEX IF EXISTS cust_relationship.idx_customer_addresses_customer_id;

CREATE INDEX IF NOT EXISTS idx_customer_addresses_customer_id
    ON cust_relationship.customer_addresses USING btree
    (customer_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: uq_customer_addresses_one_current_per_type

-- DROP INDEX IF EXISTS cust_relationship.uq_customer_addresses_one_current_per_type;

CREATE UNIQUE INDEX IF NOT EXISTS uq_customer_addresses_one_current_per_type
    ON cust_relationship.customer_addresses USING btree
    (customer_id ASC NULLS LAST, address_type COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default
    WHERE lived_until IS NULL AND deleted_at IS NULL;

-- Trigger: trg_customer_addresses_set_updated_at

-- DROP TRIGGER IF EXISTS trg_customer_addresses_set_updated_at ON cust_relationship.customer_addresses;

CREATE OR REPLACE TRIGGER trg_customer_addresses_set_updated_at
    BEFORE UPDATE 
    ON cust_relationship.customer_addresses
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();