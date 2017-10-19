CREATE OR REPLACE FUNCTION network_scan.get_baseline_host_by_most_recent_ip_address(_site_id bigint,
                                                                                    _ip_address inet)
    RETURNS SETOF network_scan.flattened_baseline_hosts_with_attributes
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- this doesn't entirely work correctly since it sometimes only matches on SD scans. Need
    -- to sit and debug this but its good enough for now.
    RETURN QUERY SELECT bh.* FROM network_scan.flattened_baseline_hosts_with_attributes AS bh,
            (SELECT * FROM network_scan.latest_scans AS ls
            LEFT JOIN network_scan.flattened_host_addresses AS fha ON ls.id=fha.scan_id
            -- Remove the in-depth scans
            WHERE ip_address = _ip_address
                AND site_id=_site_id) AS ip_hosts
        WHERE network_scan.is_same_host(bh.host_id, ip_hosts.host_id)
        AND bh.scan_type != 'service-discovery' AND  bh.scan_type != 'ip-protocol-detection';
END
$$;