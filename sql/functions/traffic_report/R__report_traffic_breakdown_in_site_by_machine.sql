CREATE OR REPLACE FUNCTION traffic_report.report_traffic_breakdown_in_site_by_machine(_site_id bigint, _start_timestamp timestamp, _end_timestamp timestamp)
    RETURNS TABLE (
        local_ip inet,
        country_name text,
        region_name text,
        rx_total_bytes bigint,
        tx_total_bytes bigint
    )
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN

RETURN QUERY SELECT
	report.local_ip,
	report.country_name,
	report.region_name,
	SUM(report.rx_total_bytes)::bigint AS rx_total_bytes,
	SUM(report.tx_total_bytes)::bigint AS tx_total_bytes
FROM traffic_report.report_traffic_breakdown_for_site(_site_id, _start_timestamp, _end_timestamp) AS report
GROUP BY (report.local_ip, report.country_name, report.region_name);

END;
$$;