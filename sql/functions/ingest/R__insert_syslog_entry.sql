--
-- Name: insert_syslog_entry(bigint, bigint, bigint, character varying, public.syslog_priority, bigint, character varying, public.syslog_facility, text); Type: FUNCTION; Schema: ingest; Owner: -
--

CREATE OR REPLACE FUNCTION ingest.insert_syslog_entry(upload_log bigint, recorder_id bigint, unix_ts bigint, program character varying, priority public.syslog_priority, pid bigint, host character varying, facility public.syslog_facility, syslog_message text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
    DECLARE
        syslog_prog_id bigint;
    BEGIN
        -- Match the program log to an existing application if we are aware of it
        SELECT ingest.insert_or_select_program_id(program) INTO syslog_prog_id;

        -- See comment in create upload log about timestamps
        INSERT INTO syslog_messages (recorder_message_id, recorder_id, logged_at, program_id, pid, host, facility, priority, message)
            VALUES (upload_log, recorder_id, TO_TIMESTAMP(unix_ts), syslog_prog_id, pid, host, facility, priority, syslog_message);
    END;
$$;

