-- Updates the recorder's software revision from the status messages

CREATE OR REPLACE FUNCTION admin.set_recorder_sw_revision(_recorder_id bigint,
                                                          _image_build bigint,
                                                          _image_type text)
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    recorder public.recorders;
BEGIN
    -- Make sure the recorder exists to begin with (will throw exception on failure)
    recorder := ingest.select_recorder_by_id(_recorder_id);

    -- Do the update
    UPDATE recorders SET image_build_date=_image_build, image_type=_image_type
        WHERE id=_recorder_id;
END;
$$;