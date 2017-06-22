-- Obsolete function for the first time I attempted this
ALTER TABLE network_scan.hosts DROP COLUMN vendor CASCADE; -- Obsolete, belongs to mac_address

-- Baseline hosts refer to if a host is expected, and how it should look in a given scan of a
-- host. This allows for simplified comparsion logic at the cost of more complex relations.

DROP TABLE IF EXISTS network_scan.baseline_hosts;
CREATE TABLE network_scan.baseline_hosts (
	id bigserial NOT NULL PRIMARY KEY,
	site_id bigint NOT NULL REFERENCES sites (id),
    scan_type network_scan.scan_type NOT NULL,
	host_id bigint NOT NULL REFERENCES network_scan.hosts (id)
);
