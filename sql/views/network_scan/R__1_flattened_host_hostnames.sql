-- Flattens out the hostnames for easier querying

-- The WHERE clause filters out the view to remove host_ids without hosts in it
-- which aids JSON building and prevents idioticy

CREATE OR REPLACE VIEW network_scan.flattened_host_hostnames AS
    SELECT nsh.id AS host_id, nshn.hostname, nshn.type FROM network_scan.hosts AS nsh
	LEFT OUTER JOIN network_scan.host_hostnames ON (nsh.id=network_scan.host_hostnames.host_id)
	LEFT OUTER JOIN network_scan.hostnames AS nshn ON (network_scan.host_hostnames.hostname_id=nshn.id)
	WHERE nshn.hostname IS NOT NULL;