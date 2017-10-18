-- Returning the IP address/MAC address is not helpful here
CREATE OR REPLACE VIEW network_scan.flattened_baseline_hosts_with_attributes AS
    SELECT bh.id, bh.site_id, bh.host_id, bh.scan_type, bh.human_name FROM network_scan.baseline_hosts AS bh
    LEFT JOIN network_scan.flattened_host_addresses AS fha ON bh.id=fha.host_id;

