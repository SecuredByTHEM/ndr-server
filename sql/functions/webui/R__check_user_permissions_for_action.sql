-- Checks ACL for user actions such as creating new users and such

CREATE OR REPLACE FUNCTION webui.check_user_permissions_for_action(_user_id bigint, _action webui.user_admin_actions) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    user_row webui.users;
BEGIN
    -- First, let's make sure we have a valid user
    --
    -- This will raise an exception if the ID is bust
    user_row = webui.select_user_by_id(_user_id);

    -- If we're a superadmin, we can see all organizations
    IF user_row.superadmin IS FALSE THEN
        -- ACL stuff goes here, which is not implemented
        RAISE EXCEPTION 'User ACLs not implemented';
    END IF;

    RETURN 't';
END
$$;
