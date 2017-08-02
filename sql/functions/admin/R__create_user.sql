-- Creates a user for the web UI; the webUI version of this function requires a user
-- to create a user as part of the auditing system. This is the base function as well
-- as used to initialize the system.

CREATE OR REPLACE FUNCTION admin.create_user(_username text, _email text, _password_hash text, _real_name text) 
    RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
    DECLARE
        insert_id bigint;
    BEGIN
        -- Creates a new organization for NDR
        INSERT INTO webui.users (username, email, password_hash, real_name) VALUES
            (_username, _email, _password_hash, _real_name) RETURNING id INTO insert_id;
        RETURN insert_id;
    END
$$;