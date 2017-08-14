-- Returns the organizations for a user
CREATE OR REPLACE FUNCTION webui.get_recorders_in_site_for_user(_user_id bigint, _site_id bigint) RETURNS SETOF public.recorders
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    org public.organizations;
    site public.sites;
    user_row webui.users;
BEGIN
    -- First, let's make sure we have a valid user
    --
    -- This will raise an exception if the ID is bust
    user_row = webui.select_user_by_id(_user_id);

    -- Pull the siteand make sure it exists
    org = admin.select_site_by_id(_site_id);

    -- If we're a superadmin, we can see all organizations
    IF user_row.superadmin IS FALSE THEN
        -- ACL stuff goes here, which is not implemented
        RAISE EXCEPTION 'User ACLs not implemented';
    END IF;


    -- Organization exists, get the sites
    RETURN QUERY SELECT * FROM recorders WHERE site_id=_site_id;
END
$$;
