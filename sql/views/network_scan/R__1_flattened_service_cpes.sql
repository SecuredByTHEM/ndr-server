-- Here we go again ...
CREATE OR REPLACE VIEW network_scan.flattened_service_cpes AS
    SELECT service_id,cpe FROM network_scan.service_cpes as sc
	    LEFT JOIN network_scan.cpes AS c ON (c.id=sc.cpe_id);