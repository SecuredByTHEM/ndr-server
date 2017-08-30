-- Retrieves a file blob from the database

CREATE OR REPLACE FUNCTION configs.get_file_blob(_file_id bigint) RETURNS bytea
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    file_blob bytea;
BEGIN
	SELECT contents INTO file_blob FROM configs.recorder_file_blobs WHERE id=_file_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'File blob % not found in database!', _file_id;
    END IF;

    RETURN file_blob;
	END
$$;