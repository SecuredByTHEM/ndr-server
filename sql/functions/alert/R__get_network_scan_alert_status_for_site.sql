-- Registers or updates an alert in the database

CREATE OR REPLACE FUNCTION alert.get_network_scan_alert_status_for_site(_site_id bigint)
    RETURNS SETOF alert.network_scan_alert_tracker
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
BEGIN
    -- Return the outstanding and pending alerts for a site
    RETURN QUERY SELECT * FROM alert.network_scan_alert_tracker WHERE site_id=_site_id;
END
$$;
