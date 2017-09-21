--- Returns a list of all site IDs for generating report emails for GeoIP

CREATE OR REPLACE FUNCTION admin.get_recorders_in_site(_site_id bigint) 
    RETURNS bigint[]
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    recorder_ids bigint[];
BEGIN
	SELECT array_agg(id) INTO recorder_ids FROM recorders WHERE site_id=_site_id;
    RETURN recorder_ids;
END
$$;