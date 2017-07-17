CREATE OR REPLACE FUNCTION snort.report_traffic_for_site_within_timeperiod(_site_id bigint, _seconds bigint)
    RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    traffic_report_cursor cursor (query_site_id bigint, interval_seconds bigint) FOR
        SELECT nsip_src.ip_address AS src_ip, nsip_dst.ip_address AS dst_ip, sum(txpackets) AS txpackets, sum(rxpackets) AS rxpackets FROM snort.traffic_reports AS sntr
        LEFT JOIN recorder_messages AS rm ON (rm.id=msg_id)
        LEFT JOIN recorders AS r ON (r.id=rm.recorder_id)
        LEFT JOIN sites AS s ON (s.id=r.site_id)
        LEFT JOIN network_scan.ip_addresses AS nsip_src ON (nsip_src.id=src)
        LEFT JOIN network_scan.ip_addresses AS nsip_dst ON (nsip_dst.id=dst)
        WHERE s.id=query_site_id
        AND rm.generated_at >= current_timestamp - (interval_seconds || ' seconds')::interval
        GROUP BY nsip_src.ip_address, nsip_dst.ip_address;

    traffic_record record;
    consolated_traffic json[];
    traffic_json json;
BEGIN
    -- open the cursor and start doing work on it
    OPEN traffic_report_cursor(query_site_id := _site_id, interval_seconds := _seconds);

    LOOP
        -- Build the JSON object for each record
        FETCH traffic_report_cursor INTO traffic_record;
        EXIT WHEN NOT FOUND;

        traffic_json := json_build_object(
            'src', traffic_record.src_ip,
            'dst', traffic_record.dst_ip,
            'rxpackets', traffic_record.rxpackets,
            'txpackets', traffic_record.txpackets
        );

        consolated_traffic := array_append(
            consolated_traffic, traffic_json
        );
    END LOOP;

    -- Now return the traffic information
    traffic_json := json_build_object(
        'consolated_traffic', consolated_traffic
    );
    RETURN traffic_json;
END
$$;
