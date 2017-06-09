CREATE OR REPLACE FUNCTION admin.select_site_by_name(_site_name text) RETURNS SETOF public.sites
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
	RETURN QUERY SELECT * FROM sites WHERE name=_site_name;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Site with name % not found', _site_name;
	END IF;

	RETURN;
END
$$;
