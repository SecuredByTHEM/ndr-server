-- Returns a recorder of all files for a recorder

CREATE OR REPLACE FUNCTION configs.get_recorder_files(_recorder_id bigint) RETURNS SETOF configs.recorder_file_versions
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Make sure the recorder exists
    PERFORM ingest.select_recorder_by_id(_recorder_id);

	RETURN QUERY SELECT * FROM configs.recorder_file_versions WHERE recorder_id=_recorder_id;
	END
$$;