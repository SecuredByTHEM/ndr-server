CREATE OR REPLACE FUNCTION traffic_report.report_traffic_breakdown_in_site_by_machine(_site_id bigint, _start_timestamp timestamp, _end_timestamp timestamp)
    RETURNS TABLE (
        id bigint,
        local_ip inet,
        global_ip inet,
        country_code char(2),
        country_name text,
        region_name text,
        city_name text,
        isp text,
        domain text,
        rx_total_bytes bigint,
        tx_total_bytes bigint
    )
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN

RETURN QUERY SELECT DISTINCT ON (local_ip, country_name, region_name)
	local_ip,
	country_name,
	region_name,
	SUM(rx_total_bytes) AS rx_total_bytes,
	SUM(tx_total_bytes) AS tx_total_bytes
FROM traffic_report.report_traffic_breakdown_by_machine(_site_id, _start_timestamp, _end_timestamp)
GROUP BY (local_ip, country_name, region_name);

END;
$$;