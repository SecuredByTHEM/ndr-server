-- Adds a host to the baseline. Scan type and the site is derieved automatically from
-- the scan that the host is part of.

CREATE OR REPLACE FUNCTION network_scan.add_host_to_baseline(_host_id bigint)
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    scan_site_id bigint;
    host_scan_type network_scan.scan_type;
BEGIN

    -- First, retrieve the site ID from the scan
    SELECT s.id INTO scan_site_id FROM network_scan.hosts AS nsh
        LEFT JOIN network_scan.scans AS nss ON (nsh.scan_id=nss.id)
        LEFT JOIN recorder_messages AS rm ON (nss.msg_id=rm.id)
        LEFT JOIN recorders AS r ON (rm.recorder_id=r.id)
        LEFT JOIN sites AS s ON (s.id=r.site_id)
        WHERE nsh.id = _host_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Host % Not Found!', _host_id;
    END IF;

    -- Now get the scan_type (we probably need to refactor a bunch of this)
    SELECT nss.scan_type INTO host_scan_type FROM network_scan.hosts AS nsh
        LEFT JOIN network_scan.scans AS nss ON (nss.id=nsh.scan_id)
        WHERE nsh.id = _host_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Internal consistency error: no scan found for host %', _host_id;
    END IF;

    INSERT INTO network_scan.baseline_hosts(site_id, scan_type, host_id) VALUES
        (scan_site_id, host_scan_type, _host_id);
END
$$;
