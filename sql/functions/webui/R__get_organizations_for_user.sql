-- Returns the organizations for a user
CREATE FUNCTION webui.get_organizations_for_user(_user_id bigint) RETURNS SETOF public.organizations
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

    RETURN QUERY SELECT * FROM organizations;
END
$$;
