-- Flattens hostnames into something easier to cross-link into the outbound connection
CREATE OR REPLACE VIEW traffic_report.flattened_internet_hostnames AS
    SELECT trkih.*, ip_address, hostname FROM traffic_report.known_internet_hostnames AS trkih
    LEFT JOIN network_scan.ip_addresses AS nsip ON (trkih.ip_id=nsip.id)
    LEFT JOIN traffic_report.seen_hostnames AS trsh ON (trkih.hostname_id=trsh.id)