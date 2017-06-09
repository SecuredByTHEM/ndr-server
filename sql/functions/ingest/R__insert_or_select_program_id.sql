--
-- Name: insert_or_select_program_id(character varying); Type: FUNCTION; Schema: ingest; Owner: -
--

CREATE OR REPLACE  FUNCTION ingest.insert_or_select_program_id(program character varying) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    program_id bigint;
BEGIN
    SELECT id INTO program_id FROM syslog_programs WHERE syslog_program=program;
    IF NOT FOUND THEN
        -- syslog programs are automatically added as they're detected and found
        INSERT INTO syslog_programs(syslog_program) VALUES (program) RETURNING id INTO program_id;
    END IF;

    RETURN program_id;
    END;
$$;