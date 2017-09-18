-- Puts the traffic reports in a saner format

CREATE OR REPLACE VIEW traffic_report.flattened_traffic_reports AS
    SELECT tr.id,
        tr.msg_id,
        tr.protocol,
        nsip_src.ip_address AS src_ip,
        trsn_src.hostname AS src_hostname,
        tr.src_port,
        nsip_dst.ip_address AS dst_ip,
        trsn_dst.hostname AS dst_hostname,
        tr.dst_port,
        tr.rx_bytes,
        tr.tx_bytes,
        tr.start_timestamp,
        tr.duration
    FROM traffic_report.traffic_reports AS tr
    LEFT JOIN network_scan.ip_addresses AS nsip_src ON (tr.src_ip_id=nsip_src.id)
    LEFT JOIN network_scan.ip_addresses AS nsip_dst ON (tr.dst_ip_id=nsip_dst.id)
    LEFT JOIN traffic_report.seen_hostnames AS trsn_src ON (tr.src_hostname_id=trsn_src.id)
    LEFT JOIN traffic_report.seen_hostnames AS trsn_dst ON (tr.dst_hostname_id=trsn_dst.id);