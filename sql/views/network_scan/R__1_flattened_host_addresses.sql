-- Flattens out the network scan host addresses so foriegn keys are resolved

CREATE OR REPLACE VIEW network_scan.flattened_host_addresses AS
    SELECT  nsh.id AS host_id,
        nsh.scan_id,
        nsh.state,
        nsh.reason,
        nsh.reason_ttl,
        nsip.ip_address,
        nsma.mac_address,
        nsh.vendor
    FROM network_scan.hosts AS nsh
    LEFT JOIN network_scan.ip_addresses AS nsip ON (nsh.ip_address_id=nsip.id)
    LEFT JOIN network_scan.mac_addresses AS nsma ON (nsh.mac_address_id=nsma.id);