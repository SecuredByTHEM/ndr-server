CREATE OR REPLACE VIEW network_scan.flattened_host_osmatches_osclasses AS 
    SELECT host_osmatch_id, osclass_id, accuracy, vendor, osgen, ostype, osfamily FROM network_scan.host_osmatches_osclasses AS hosmosc
	LEFT JOIN network_scan.osclasses AS osc ON (hosmosc.osclass_id=osc.id);