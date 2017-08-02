-- Activates a user, denoting that their email is valid

CREATE OR REPLACE FUNCTION admin.activate_user(_user_id bigint)
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
    BEGIN
        -- Creates a new organization for NDR
        UPDATE webui.users SET active = 't' WHERE id=_user_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'UserID % not found!', _user_id;
        END IF;

        RETURN;
    END;
$$;