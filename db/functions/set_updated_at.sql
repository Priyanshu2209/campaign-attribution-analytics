-- =============================================================
-- File:    db/functions/set_updated_at.sql
-- Purpose: Reusable trigger function that sets updated_at to the
--          current time whenever a row is updated.
-- Run order: db/schemas -> db/functions -> db/migrations
-- =============================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();   -- NEW = the row as it will be saved
    RETURN NEW;                -- hand the changed row back to PostgreSQL
END;
$$;

COMMENT ON FUNCTION public.set_updated_at() IS
    'Trigger function: sets updated_at = now() before every UPDATE.';
