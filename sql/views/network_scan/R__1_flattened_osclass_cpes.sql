CREATE OR REPLACE VIEW network_scan.flattened_osclass_cpes AS
    SELECT osclass_id, cpe FROM network_scan.osclasses as osc
	LEFT JOIN network_scan.osclass_cpes AS osc_cpes ON (osc.id=osc_cpes.osclass_id)
	LEFT JOIN network_scan.cpes AS cpes ON (cpes.id=osc_cpes.cpe_id);