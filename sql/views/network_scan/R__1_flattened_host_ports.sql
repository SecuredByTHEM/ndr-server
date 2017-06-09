-- Flattens the port status with the port information

CREATE OR REPLACE VIEW network_scan.flattened_host_ports AS
    SELECT h.id AS host_id, hps.id AS host_port_id, p.portid, p.protocol, hps.state, hps.reason, hps.reason_ttl FROM network_scan.hosts AS h
    LEFT OUTER JOIN network_scan.host_port_status AS hps ON (h.id=hps.host_id)
    LEFT OUTER JOIN network_scan.ports AS p ON (hps.port_id=p.id)