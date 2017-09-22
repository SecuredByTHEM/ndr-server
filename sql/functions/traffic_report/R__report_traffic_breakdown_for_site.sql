CREATE OR REPLACE FUNCTION traffic_report.report_traffic_breakdown_for_site(_site_id bigint, _start_timestamp timestamp, _end_timestamp timestamp)
    RETURNS TABLE (
        local_ip inet,
        global_ip inet,
        country_name text,
        region_name text,
        city_name text,
        isp text,
        domain text,
        total_rx_bytes bigint,
        total_tx_bytes bigint
    )
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    -- Breaks down traffic based by incoming machine and what not
    recorder_ids bigint[];
    recorder_id bigint;
    msg_ids bigint[];
BEGIN
    -- Retrieve all the recorders in the site
    recorder_ids := admin.get_recorders_in_site(_site_id);
    FOREACH recorder_id IN ARRAY recorder_ids LOOP
        msg_ids := array_cat(
            msg_ids, 
            admin.get_recorder_message_ids_recieved_in_period(
                recorder_id,
                'traffic_report',
                _start_timestamp,
                _end_timestamp
            )
        );
    END LOOP;

    -- Get the message IDs for this period

    RETURN QUERY 
        SELECT
            fot.local_ip,
            fot.global_ip,
            COALESCE(fot.country_name, 'Unknown') AS country_name,
            COALESCE(fot.region_name, 'Unknown') AS region_name,
            COALESCE(fot.city_name, 'Unknown') AS city_name,
            COALESCE(fot.isp, 'Unknown') AS isp,
            COALESCE(fot.domain, 'Unknown') AS domain,
            SUM(tr.rx_bytes) AS rx_bytes_total,
            SUM(tr.tx_bytes) AS tx_bytes_total
        FROM traffic_report.full_outbound_traffic AS fot 
        LEFT JOIN traffic_report.traffic_reports AS tr ON (tr.id=fot.traffic_report_id)
        WHERE tr.msg_id = ANY(msg_ids)
        GROUP BY (fot.local_ip,
                  fot.global_ip,
                  fot.country_name,
                  fot.region_name,
                  fot.city_name,
                  fot.isp,
                  fot.domain);
END;
$$
