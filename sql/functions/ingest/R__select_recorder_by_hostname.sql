--
-- Name: select_recorder_by_hostname(character varying); Type: FUNCTION; Schema: ingest; Owner: -
--

CREATE OR REPLACE FUNCTION ingest.select_recorder_by_hostname(_hostname character varying) RETURNS SETOF public.recorders
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
	RETURN QUERY SELECT * FROM recorders WHERE hostname=_hostname;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Recorder with hostname % not found', _hostname;
	END IF;

	RETURN;
END
$$;