-- Checks if a user is allowed to access a given site
--
-- Raises exception if not true

CREATE OR REPLACE FUNCTION webui.check_site_acl(_user_id bigint, _site_id bigint) RETURNS boolean
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
        RAISE EXCEPTION 'User is not allowed to access this site';
    END IF;

    RETURN 't';
END
$$;
