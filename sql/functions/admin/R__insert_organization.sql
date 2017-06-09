--
-- Name: insert_organization(character varying); Type: FUNCTION; Schema: admin; Owner: -
--

CREATE OR REPLACE FUNCTION admin.insert_organization(org_name character varying) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
    DECLARE
        insert_id bigint;
    BEGIN
        -- Creates a new organization for NDR
        INSERT INTO organizations (name) VALUES (org_name) RETURNING id INTO insert_id;
        RETURN insert_id;
    END;
$$;
