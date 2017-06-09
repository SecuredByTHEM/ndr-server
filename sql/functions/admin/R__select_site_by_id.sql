--
-- Name: select_site_by_id(bigint); Type: FUNCTION; Schema: admin; Owner: -
--

CREATE OR REPLACE FUNCTION admin.select_site_by_id(_site_id bigint) RETURNS SETOF public.sites
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
	RETURN QUERY SELECT * FROM sites WHERE id=_site_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Site with ID % not found', _site_id;
	END IF;

	RETURN;
END
$$;
