-- Returns the alert status for a site

CREATE OR REPLACE FUNCTION alert.register_or_update_network_scan_alert(
        _site_id bigint,
        _host_id bigint)
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    alerted_hosts bigint[];
    alerted_host_id bigint;
    existing_host_id bigint;
    found boolean;
BEGIN
    -- Pull all the alerted hosts into the bigint
    alerted_hosts := array(SELECT host_id FROM alert.network_scan_alert_tracker
                     WHERE site_id=_site_id);
    
    -- Determine if we've seen this host prior and then update it
    found := 'f';
    FOREACH alerted_host_id IN ARRAY alerted_hosts
    LOOP
        -- Do we have a hit?
        IF network_scan.is_same_host(alerted_host_id, _host_id) THEN
            found = 't';
            existing_host_id = alerted_host_id;
        END IF;
    END LOOP; -- baseline_hosts

    IF found = 't' THEN
        -- Update the last seen value to NOW

        -- We use timeofday() here vs. NOW() for allowing ease of testing so that the updated
        -- timestamp can be checked within a transaction.
        UPDATE alert.network_scan_alert_tracker SET last_seen = timeofday()::timestamp
            WHERE host_id=existing_host_id;
    ELSE
        -- Register it into the alert tracker
        INSERT INTO alert.network_scan_alert_tracker(site_id, host_id) VALUES
            (_site_id, _host_id);
    END IF;

END
$$;
