CREATE OR REPLACE FUNCTION traffic_report.report_internet_host_breakdown_for_site(_site_id bigint, _start_timestamp timestamp, _end_timestamp timestamp)
    RETURNS TABLE (
        local_ip inet,
        global_ip inet,
        global_hostname text,
        isp text
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
    recorder_ids := admin.get_all_recorders_ids_in_site(_site_id);
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
        SELECT DISTINCT fot.local_ip, fot.global_ip, fot.global_hostname, fot.isp
        FROM traffic_report.full_outbound_traffic AS fot 
        LEFT JOIN traffic_report.traffic_reports AS tr ON (tr.id=fot.traffic_report_id)
        WHERE tr.msg_id = ANY(msg_ids);
END;
$$
