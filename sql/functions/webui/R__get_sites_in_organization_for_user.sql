-- Returns the organizations for a user
CREATE OR REPLACE FUNCTION webui.get_sites_in_organization_for_user(_user_id bigint, _org_id bigint) RETURNS SETOF public.sites
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    org public.organizations;
    user_row webui.users;
BEGIN
    -- First, let's make sure we have a valid user
    --
    -- This will raise an exception if the ID is bust
    user_row = webui.select_user_by_id(_user_id);

    -- Pull the organization and make sure it exists
    org = admin.select_organization_by_id(_org_id);

    -- If we're a superadmin, we can see all organizations
    IF user_row.superadmin IS FALSE THEN
        -- ACL stuff goes here, which is not implemented
        RAISE EXCEPTION 'User ACLs not implemented';
    END IF;


    -- Organization exists, get the sites
    RETURN QUERY SELECT * FROM sites WHERE org_id=_org_id;
END
$$;
