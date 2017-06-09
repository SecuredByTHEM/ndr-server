--
-- Name: insert_site(bigint, character varying); Type: FUNCTION; Schema: admin; Owner: -
--

CREATE OR REPLACE FUNCTION admin.insert_site(_org_id bigint, _site_name character varying) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
    DECLARE
        insert_id bigint;
    BEGIN
        -- Creates a new site for NDR
        INSERT INTO sites (org_id, name) VALUES (_org_id, _site_name) RETURNING id INTO insert_id;
        RETURN insert_id;
    END;
$$;
