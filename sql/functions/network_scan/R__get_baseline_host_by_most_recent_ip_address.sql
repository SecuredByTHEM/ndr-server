CREATE OR REPLACE FUNCTION network_scan.get_baseline_host_by_most_recent_ip_address(_site_id bigint,
                                                                                    _ip_address inet)
    RETURNS SETOF network_scan.flattened_baseline_hosts_with_attributes
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY SELECT bh.* FROM network_scan.flattened_baseline_hosts_with_attributes AS bh,
            (SELECT * FROM network_scan.latest_scans AS ls
            LEFT JOIN network_scan.flattened_host_addresses AS fha ON ls.id=fha.scan_id
            -- Remove the in-depth scans
            WHERE scan_type != 'service-discovery' AND  scan_type != 'ip-protocol-detection'
                AND ip_address = _ip_address
                AND site_id=_site_id) AS ip_hosts
        WHERE network_scan.is_same_host(bh.host_id, ip_hosts.host_id)
        AND bh.scan_type=ip_hosts.scan_type;
END
$$;