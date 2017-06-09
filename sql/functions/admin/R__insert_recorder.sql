--
-- Name: insert_recorder(bigint, character varying, character varying); Type: FUNCTION; Schema: admin; Owner: -
--

CREATE OR REPLACE FUNCTION admin.insert_recorder(_site_id bigint, _human_name character varying, _hostname character varying) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
    DECLARE
       	insert_id bigint;
    BEGIN
	-- Creates a new organization for NDR
        INSERT INTO recorders (site_id, human_name, hostname) VALUES 
               	(_site_id, _human_name, _hostname) RETURNING id INTO insert_id;
        RETURN insert_id;
    END;
$$;
