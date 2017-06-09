CREATE OR REPLACE VIEW network_scan.flattened_script_output AS
    SELECT host_port_id, script_name, output, elements FROM network_scan.host_port_script_outputs AS hpso
	LEFT JOIN network_scan.script_outputs AS so ON (so.id=hpso.script_output_id);