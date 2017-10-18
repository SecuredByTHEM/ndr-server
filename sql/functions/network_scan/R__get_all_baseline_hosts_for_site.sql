CREATE OR REPLACE FUNCTION network_scan.get_all_baseline_hosts_for_site(_site_id bigint)
    RETURNS SETOF network_scan.flattened_baseline_hosts_with_attributes
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY SELECT * FROM network_scan.flattened_baseline_hosts_with_attributes
        WHERE site_id=_site_id;
END
$$;
