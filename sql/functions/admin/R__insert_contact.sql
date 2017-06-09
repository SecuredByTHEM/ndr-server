--
-- Name: insert_contact(bigint, public.contact_type, character varying); Type: FUNCTION; Schema: admin; Owner: -
--

CREATE OR REPLACE FUNCTION admin.insert_contact(org_id bigint, method public.contact_type, value character varying) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
    DECLARE
        insert_id bigint;
    BEGIN
        -- Creates a new organization for NDR
        INSERT INTO contacts (org_id, method, value) VALUES (org_id, method, value) RETURNING id INTO insert_id;
        RETURN insert_id;
    END;
$$;