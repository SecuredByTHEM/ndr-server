--
-- Name: create_upload_log(bigint, public.recorder_message_type, bigint); Type: FUNCTION; Schema: ingest; Owner: -
--

CREATE OR REPLACE  FUNCTION ingest.create_upload_log(recorder bigint, upload_type public.recorder_message_type, generated_at_unix_ts bigint) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    rec_msg_id bigint;
    BEGIN
        -- This function, like several other ones gets UNIX based epoch timestamps
        -- when it loads due to the fact that we use them everywhere for sheer
        -- sanity realizes. PostgreSQL doesn't support these directly, but uses
        -- an internal timestamp field which is more flexible and understands
        -- days/weeks/months/etc.
        --
        -- As such we need to convert these timestamps to pgSQL timestamps. There's
        -- one (minor) catch with these. They don't know about leapseconds. To be
        -- frank, I DON'T CARE! We can deal with one second of drift when one of
        -- those inferal things come down the pipe
        --
        -- For received_at, we're using the time the message was processed successfully
        -- into the database as we only accept messages upon successful commit.
        --
        -- NOTE: Bad juju can happen in the database server clock is off, but there's no
        -- way to determine if the DB server is wrong, and we don't want to reject a message
        -- if a recorder thinks it's in the future
        
        INSERT INTO recorder_messages(recorder_id, message_type, generated_at, received_at) VALUES 
            (recorder, upload_type, TO_TIMESTAMP(generated_at_unix_ts), NOW()) RETURNING id INTO rec_msg_id;
        RETURN rec_msg_id;
    END;
$$;
