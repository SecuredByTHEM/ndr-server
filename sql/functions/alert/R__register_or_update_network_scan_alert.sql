-- Returns the alert status for a site

CREATE OR REPLACE FUNCTION alert.register_or_update_network_scan_alert(
        _site_id bigint,
        _host_id bigint)
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
BEGIN
    -- Temp. Just insert the alert as is
    INSERT INTO alert.network_scan_alert_tracker(site_id, host_id) VALUES
        (_site_id, _host_id);
    -- First, get a list of recorder alerts

END
$$;
