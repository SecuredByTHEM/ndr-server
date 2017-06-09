--
-- Name: select_organization_by_id(bigint); Type: FUNCTION; Schema: admin; Owner: -
--

CREATE FUNCTION admin.select_organization_by_id(org_id bigint) RETURNS SETOF public.organizations
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
	RETURN QUERY SELECT id,name FROM organizations WHERE id=org_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Organization with ID % not found', org_id;
	END IF;

	RETURN;
END
$$;
