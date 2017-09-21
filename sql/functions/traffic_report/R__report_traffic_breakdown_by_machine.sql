CREATE OR REPLACE FUNCTION traffic_report.report_traffic_breakdown_by_machine(_site_id bigint, _start_datetime timestamp, _end_datetime timestamp)
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
        rx_bytes_total bigint,
        tx_bytes_total bigint
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
                _start_datetime,
                _end_datetime
            )
        );
    END LOOP;

    -- Get the message IDs for this period

    RETURN QUERY SELECT trfot.id,
            trfot.local_ip,
            trfot.global_ip,
            COALESCE(trfot.country_code, 'ZZ') AS country_code,
            COALESCE(trfot.country_name, 'Unknown') AS country_name,
            COALESCE(trfot.region_name, 'Unknown') AS region_name,
            COALESCE(trfot.city_name, 'Unknown') AS city_name,
            COALESCE(trfot.isp, 'Unknown') AS isp,
            COALESCE(trfot.domain, 'Unknown') AS domain,
            sums.rx_bytes_total,
            sums.tx_bytes_total
        FROM traffic_report.full_outbound_traffic AS trfot
        INNER JOIN (
            -- Embrace deep magic. This groups all distinct global/local IP pairs from
            -- postprocessing, sums it, and then spits total number of bytes
            SELECT DISTINCT ON (trnot.global_ip_id, trnot.local_ip_id)
            trnot.id,
            SUM(tr.rx_bytes) AS rx_bytes_total,
            SUM(tr.tx_bytes) AS tx_bytes_total
            FROM traffic_report.network_outbound_traffic AS trnot
            LEFT JOIN traffic_report.traffic_reports AS tr ON (tr.id=trnot.traffic_report_id)
            WHERE trnot.msg_id = ANY(msg_ids)
            GROUP BY (trnot.id, trnot.global_ip_id, trnot.local_ip_id)
        ) AS sums ON (sums.id=trfot.id);

END;
$$
