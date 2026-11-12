-- =============================================================
-- Migration 002: cust_relationship.customer_addresses
-- Purpose: Address history for each customer.
--          A move = set lived_until on the old row, then add a
--          new row. Current address = lived_until IS NULL.
--
-- Needs first: db/schemas/create_schemas.sql
--              db/functions/set_updated_at.sql
--              db/migrations/001_create_customers.sql
-- =============================================================

CREATE TABLE IF NOT EXISTS cust_relationship.customer_addresses(
	customer_address_id BIGINT GENERATED ALWAYS AS IDENTITY,
	customer_id BIGINT NOT NULL, 
	address_type VARCHAR(20) NOT NULL,
	unit_number VARCHAR(10),
	address_line1 VARCHAR(200) NOT NULL,
	address_line2 VARCHAR(200),
	city VARCHAR(100) NOT NULL,
	province CHAR(2) NOT NULL,
	postal_code CHAR(7) NOT NULL,
	lived_from DATE NOT NULL DEFAULT CURRENT_DATE,
	lived_until DATE,
	create_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,                

	CONSTRAINT pk_customer_addresses
		PRIMARY KEY (customer_address_id),

	CONSTRAINT fk_customer_addresses_customer
		FOREIGN KEY (customer_id)
		REFERENCES cust_relationship.customers(customer_id),

	CONSTRAINT chk_customer_addresses_address_type
		CHECK(address_type IN ('residential', 'mailing','business')),

	CONSTRAINT chk_customer_addresses_province
		CHECK(province IN ('AB','BC','MB','NB','NL','NS','NT','NU','ON','PE','QC','SK','YT')),

	-- Canadian format: letter digit letter, space, digit letter digit (e.g. M5V 2T6)
    CONSTRAINT chk_customer_addresses_postal_code
        CHECK (postal_code ~ ('^[A-Z][0-9][A-Z] [0-9][A-Z][0-9]$')),

    -- Can't stop living somewhere before moving in
    CONSTRAINT chk_customer_addresses_lived_dates
        CHECK (lived_until >= lived_from)
	
);

ALTER TABLE IF EXISTS cust_relationship.customer_addresses
    OWNER to campaign_admin;
	
COMMENT ON TABLE cust_relationship.customer_addresses IS
    'Address history per customer. Current address = lived_until IS NULL and deleted_at IS NULL.';
COMMENT ON COLUMN cust_relationship.customer_addresses.lived_from IS
    'Real-world move-in date (not the date it was entered).';
COMMENT ON COLUMN cust_relationship.customer_addresses.lived_until IS
    'Real-world last day at this address. NULL = current address.';
COMMENT ON COLUMN cust_relationship.customer_addresses.deleted_at IS
    'Soft delete, only for rows entered by mistake. A move uses lived_until instead.';

--Indexes
CREATE INDEX IF NOT EXISTS idx_customer_addresses_customer_id
	ON cust_relationship.customer_addresses(customer_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_customer_addresses_one_current_per_type
	ON cust_relationship.customer_addresses(customer_id,address_type)
	where lived_until IS NULL AND deleted_at IS NULL;


--trigger for update
CREATE OR REPLACE TRIGGER trg_customer_addresses_set_updated_at
	BEFORE UPDATE ON cust_relationship.customer_addresses
	FOR EACH ROW
	EXECUTE FUNCTION public.set_updated_at();

COMMIT;


