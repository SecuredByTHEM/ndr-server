CREATE OR REPLACE VIEW network_scan.flattened_host_osmatches AS 
    SELECT hom.id as host_osmatch_id, h.id as host_id, o.name, hom.accuracy FROM network_scan.hosts AS h
        LEFT JOIN network_scan.host_osmatches AS hom ON (h.id=hom.host_id)
        LEFT JOIN network_scan.osmatches AS o ON (hom.osmatch_id=o.id);