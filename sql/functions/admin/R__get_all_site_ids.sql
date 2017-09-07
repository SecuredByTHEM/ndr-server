--- Returns a list of all site IDs for generating report emails for GeoIP

CREATE OR REPLACE FUNCTION admin.get_all_site_ids() 
    RETURNS TABLE (id bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
	RETURN QUERY SELECT s.id FROM public.sites AS s;
END
$$;