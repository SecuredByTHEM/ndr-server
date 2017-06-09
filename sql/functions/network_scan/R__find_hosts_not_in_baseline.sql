-- Attempts to compare hosts in an attempt to determine changes in changes over time

CREATE OR REPLACE FUNCTION network_scan.find_hosts_not_in_baseline(_scan_id bigint)
 RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    site_id bigint;
    baseline_inner_query varchar;
    full_match_join varchar;
    full_matches record;
BEGIN
    -- Hosts can be the same even though their specific information is not 100% identical.
    --
    -- For example, DHCP clients can move around the network depending on their lease times
    -- As such, we need to apply the following logic to determine if they're the same host
    -- from scan to scan
    --
    -- If both the MAC Address and IP Address match across scans, we are reasonably confident we're
    -- looking at the same thing.
    --
    -- If the IPs don't match but the MAC addresses to, we can assume that it was a DHCP IP change.
    
    -- First things first, get the site id
    SELECT site_id INTO site_id FROM network_scan.scans AS nss
        LEFT JOIN recorder_messages AS rm ON (nss.msg_id=rm.id)
        LEFT JOIN recorders AS r ON (rm.recorder_id=r.id)
        LEFT JOIN sites AS s ON (r.site_id=s.id) WHERE
        nss.scan_id=_scan_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Scan ID % not found or not assoicated with a site!', _scan_id;
    END IF;

    -- Set the inner join to help make the code easier

    -- The inner join expands the baseline hosts between and the scan that they were taken from
    baseline_inner_query := 'SELECT bh.id 
        AS baseline_id, h.id AS host_id, h.mac_address_id, h.ip_address_id 
        FROM network_scan.hosts AS h 
	    INNER JOIN network_scan.baseline_hosts AS bh ON (h.id=bh.host_id) 
        WHERE bh.site_id=' + site_id;

    -- Header for match query
    full_match_join := 'SELECT h.id,baseline_id FROM network_scan.hosts AS h INNER JOIN ('
                       + baseline_inner_query 
                       + ') AS baseline_addresses ON 
                    	(baseline_addresses.mac_address_id=h.mac_address_id) AND
	                    (baseline_addresses.ip_address_id=h.ip_address_id);';

END;
$$;