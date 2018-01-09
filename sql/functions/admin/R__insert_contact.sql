--
-- Name: insert_contact(bigint, public.contact_type, character varying); Type: FUNCTION; Schema: admin; Owner: -
--

DROP FUNCTION IF EXISTS admin.insert_contact(bigint, contact_type, character varying);
CREATE OR REPLACE FUNCTION admin.insert_contact(org_id bigint,
                                                method public.contact_type,
                                                value character varying,
                                                output_format contact_output_formats) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
    DECLARE
        insert_id bigint;
    BEGIN
        -- Creates a new organization for NDR
        INSERT INTO contacts (org_id, method, value, output_format)
            VALUES (org_id, method, value, output_format) RETURNING id INTO insert_id;
        RETURN insert_id;
    END;
$$;