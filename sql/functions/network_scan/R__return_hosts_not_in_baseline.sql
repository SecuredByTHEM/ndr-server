-- Looks at a scan and determines the hosts not present in the baseline scan

CREATE OR REPLACE FUNCTION network_scan.return_hosts_not_in_baseline(_scan_id bigint)
    RETURNS bigint[]
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    this_scan network_scan.scans;
    scan_site_id bigint;
    hosts_not_found bigint[];
    scan_hosts bigint[];
    baseline_hosts bigint[];
BEGIN
    -- First we need to retrieve out scan, and then get our site_id from it
    SELECT * FROM network_scan.scans WHERE id = _scan_id INTO this_scan;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Scan % Not Found!', _scan_id;
    END IF;

    -- FIXME: Likely need to refactor this to its own function
    SELECT s.id INTO scan_site_id FROM network_scan.scans AS nss 
        LEFT JOIN recorder_messages AS rm ON (nss.msg_id=rm.id)
        LEFT JOIN recorders AS r ON (rm.recorder_id=r.id)
        LEFT JOIN sites AS s ON (s.id=r.site_id)
        WHERE rm.id = this_scan.msg_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Found dangling scan reference. Cannot determine site id!';
    END IF;

    RAISE NOTICE 'Site ID %', scan_site_id;

    scan_hosts := array(
        SELECT id FROM network_scan.hosts WHERE scan_id=_scan_id  AND reason != 'localhost-response'
    );

    -- It's theorically possible (though very unlikely) we might get a blank scan
    IF NOT FOUND THEN
        RAISE WARNING 'No hosts found in scan %', _scan_id;
        RETURN hosts_not_found; -- which is empty
    END IF;

    -- Now get our list of scan results that match this scan type so we know what to compare
    -- against and do more in-depth checks against.
    baseline_hosts := array(
        SELECT host_id FROM network_scan.baseline_hosts
        WHERE site_id=scan_site_id AND
        scan_type=this_scan.scan_type);

    DECLARE
        scan_host_id bigint;
        baseline_host_id bigint;
        found boolean;
    BEGIN
    FOREACH scan_host_id IN ARRAY scan_hosts
    LOOP
        -- If anyone knows if plPgSQL has a good way to escape a nested loop, let me know
        found := 'f';

        FOREACH baseline_host_id IN ARRAY baseline_hosts
        LOOP
            -- Do we have a hit?
            IF network_scan.is_same_host(scan_host_id, baseline_host_id) THEN
                found = 't';
                baseline_hosts := array_remove(baseline_hosts, baseline_host_id);
            END IF;
        END LOOP; -- baseline_hosts


        IF found = 'f' THEN
            hosts_not_found := array_append(hosts_not_found, scan_host_id);
        END IF;

        -- RAISE NOTICE 'Host ID %', scan_host_id;
    END LOOP; -- scan_hosts

    END;
    RETURN hosts_not_found;
END
$$;
