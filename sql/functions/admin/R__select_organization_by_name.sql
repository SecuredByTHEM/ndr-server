CREATE FUNCTION admin.select_organization_by_name(org_name text) RETURNS SETOF public.organizations
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
	RETURN QUERY SELECT id,name FROM organizations WHERE name=name;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Organization with name % not found', org_name;
	END IF;

	RETURN;
END
$$;
