-- Returns the message IDs of all recorder messages for a given interval based 
-- on the Received By date


CREATE OR REPLACE FUNCTION admin.get_recorder_message_ids_recieved_in_period(
    _recorder_id bigint,
    _message_type recorder_message_type,
    _start_timestamp timestamp,
    _end_timestamp timestamp
) RETURNS TABLE (id bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
	RETURN QUERY SELECT s.id FROM public.recorder_messages AS s WHERE
        s.recorder_id = recorder_id AND
        s.received_at >= _start_timestamp AND
        s.received_at <= _end_timestamp AND
        s.message_type=_message_type;
END
$$;
