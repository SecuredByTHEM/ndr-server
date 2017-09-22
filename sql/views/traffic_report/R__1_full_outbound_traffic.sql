-- A full look at all outbound traffic in site with the geoip information mixed in. Still WIP

CREATE OR REPLACE VIEW traffic_report.full_outbound_traffic AS
    SELECT trnot.id,
        trnot.msg_id,
        trnot.traffic_report_id,
        nsip_local.ip_address AS local_ip,
        nsip_global.ip_address AS global_ip,
        trsh.hostname AS global_hostname,
        country_code,
        country_name,
        region_name,
        city_name,
        isp,
        domain
    FROM traffic_report.network_outbound_traffic AS trnot
    LEFT JOIN network_scan.ip_addresses AS nsip_local ON trnot.local_ip_id=nsip_local.id
    LEFT JOIN network_scan.ip_addresses AS nsip_global ON trnot.global_ip_id=nsip_global.id
    LEFT JOIN traffic_report.traffic_report_internet_hostnames AS trih ON trnot.traffic_report_id=trih.traffic_report_id
    LEFT JOIN traffic_report.known_internet_hostnames AS trkih ON trkih.id=trih.internet_hostname_id
    LEFT JOIN traffic_report.seen_hostnames AS trsh ON trkih.hostname_id=trsh.id
    LEFT JOIN traffic_report.network_outbound_traffic_geoip_info AS trnotgi ON trnot.id=trnotgi.network_outbound_traffic_id
    LEFT JOIN traffic_report.geoip_information AS trgi ON trgi.id=trnotgi.geoip_information_id;
