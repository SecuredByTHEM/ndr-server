CREATE OR REPLACE FUNCTION network_scan.get_baseline_host_by_most_recent_ip_address(_site_id bigint,
                                                                                    _ip_address inet)
    RETURNS SETOF network_scan.flattened_baseline_hosts_with_attributes
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- this doesn't entirely work correctly since it sometimes only matches on SD scans. Need
    -- to sit and debug this but its good enough for now.
    RETURN QUERY SELECT DISTINCT bh.* FROM network_scan.flattened_baseline_hosts_with_attributes AS bh,
            (SELECT host_id, scan_type FROM network_scan.flattened_host_addresses AS fha
             LEFT JOIN network_scan.scans AS nss ON (fha.scan_id=nss.id)
             LEFT JOIN public.recorder_messages AS rm ON (rm.id=nss.msg_id)
             LEFT JOIN recorders AS r ON (r.id=rm.recorder_id)
             LEFT JOIN sites AS s ON (s.id=r.site_id)
             WHERE fha.ip_address = _ip_address AND  s.id=_site_id
            ORDER BY host_id DESC LIMIT 10) AS ip_hosts
        WHERE network_scan.is_same_host(bh.host_id, ip_hosts.host_id)
        AND bh.scan_type = ip_hosts.scan_type;
END
$$;