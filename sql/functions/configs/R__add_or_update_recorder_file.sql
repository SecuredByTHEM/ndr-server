-- Updates or replaces a file on the recorder

CREATE OR REPLACE FUNCTION configs.add_or_update_recorder_files(_recorder_id bigint,
                                                                _file_type public.recorder_files,
                                                                _file bytea)
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    old_file_blob_id bigint;
    new_file_blob_id bigint;
    file_hash text;
    file_record_id bigint;
BEGIN
    -- Make sure the recorder exists
    PERFORM ingest.select_recorder_by_id(_recorder_id);

    -- Hash the file and save the result, then stick it into the files table
    SELECT encode(digest(_file, 'sha256'), 'hex') INTO file_hash;
    INSERT INTO configs.recorder_file_blobs (contents) VALUES (_file) RETURNING id INTO new_file_blob_id;

    -- Now comes the fun part, if the file already existed in the database, we need to update
    -- the records table and delete the old one.
    SELECT id, file_blob_id INTO file_record_id, old_file_blob_id
         FROM configs.recorder_file_versions WHERE recorder_id=_recorder_id AND file_type=_file_type;

    IF FOUND THEN
        -- Update the existing recorder to point to the new blob and delete the old file
        UPDATE configs.recorder_file_versions SET 
            file_blob_id=new_file_blob_id,
            expected_sha256=file_hash
        WHERE id=file_record_id;

        DELETE FROM configs.recorder_file_blobs WHERE id=old_file_blob_id;
    ELSE
        -- Simply add the new record
        INSERT INTO configs.recorder_file_versions (recorder_id, file_type, expected_sha256, file_blob_id)
            VALUES (_recorder_id, _file_type, file_hash, new_file_blob_id);
    END IF;
    END
$$;
