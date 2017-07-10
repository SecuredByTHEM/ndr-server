CREATE OR REPLACE  FUNCTION alert.record_alert_msg(_msg_id bigint, _program text, _msg text) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    msg_id bigint;
BEGIN
    INSERT INTO alert.alert_msg_history (msg_id, program, message) VALUES(_msg_id, _program, _msg) 
        RETURNING id INTO msg_id;
    RETURN msg_id;
END;
$$;
