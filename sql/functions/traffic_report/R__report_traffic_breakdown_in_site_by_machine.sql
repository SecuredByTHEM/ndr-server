CREATE OR REPLACE FUNCTION traffic_report.report_traffic_breakdown_in_site_by_machine(_site_id bigint, _start_timestamp timestamp, _end_timestamp timestamp)
    RETURNS TABLE (
        local_ip inet,
        country_name text,
        region_name text,
        total_rx_bytes bigint,
        total_tx_bytes bigint
    )
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
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

    RETURN QUERY 
        SELECT 
            fot.local_ip,
            COALESCE(fot.country_name, 'Unknown'),
            COALESCE(fot.region_name, 'Unknown'),
            SUM(tr.rx_bytes) AS rx_bytes_total,
            SUM(tr.tx_bytes) AS tx_bytes_total
        FROM traffic_report.full_outbound_traffic AS fot 
        LEFT JOIN traffic_report.traffic_reports AS tr ON (tr.id=fot.traffic_report_id)
        WHERE tr.msg_id = ANY(msg_ids)
        GROUP BY (fot.local_ip, fot.country_name, fot.region_name);
END;
$$;