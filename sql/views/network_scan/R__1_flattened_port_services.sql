-- Flattens out the host_port_id table to the services table
CREATE VIEW network_scan.flattened_port_services AS
SELECT host_port_id, s.id AS service_id, s.name, hps.confidence, s.method, version, product, extrainfo, tunnel, proto, rpcnum, lowver, highver, hostname, ostype, devicetype, servicefp FROM network_scan.host_port_services AS hps
	LEFT JOIN network_scan.services AS s ON (s.id=hps.service_id);