-- Makes a user a super administrator

CREATE OR REPLACE FUNCTION admin.make_user_superadmin(_user_id bigint)
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
    BEGIN
        -- Creates a new organization for NDR
        UPDATE webui.users SET superadmin = 't' WHERE id=_user_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'UserID % not found!', _user_id;
        END IF;

        RETURN;
    END;
$$;
