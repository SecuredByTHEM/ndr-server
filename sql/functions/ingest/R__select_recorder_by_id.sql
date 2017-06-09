--
-- Name: select_recorder_by_id(bigint); Type: FUNCTION; Schema: ingest; Owner: -
--

CREATE OR REPLACE FUNCTION ingest.select_recorder_by_id(_recorder_id bigint) RETURNS SETOF public.recorders
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
	RETURN QUERY SELECT * FROM recorders WHERE id=_recorder_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Recorder with ID % not found', _recorder_id;
	END IF;

	RETURN;
END
$$;