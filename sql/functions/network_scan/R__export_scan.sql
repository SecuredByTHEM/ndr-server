-- Returns a scan result in such a way that I can get the JSON object back out of the database

CREATE OR REPLACE FUNCTION network_scan.export_scan(_scan_id bigint) RETURNS json AS $$
DECLARE
    scan_json json;
    scan_row network_scan.scans;
    current_host_id bigint;
    host_ids bigint[];
    host_json_array json[];
BEGIN
    -- This basically works in reverse from import_scan, though we have some views that help
    -- simplify returning the data out of the pipe

    -- First, grab the scan from the scan table, we'll need the info later, and this lets us
    -- check that we don't have gibberish coming in
    SELECT * INTO scan_row FROM network_scan.scans WHERE id=_scan_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Scan ID % not found', _scan_id;
    END IF;

    -- The host JSON generation was moved to it's own function
    host_ids := array(SELECT id FROM network_scan.hosts WHERE scan_id=_scan_id);
    FOREACH current_host_id IN ARRAY host_ids
    LOOP
        host_json_array := array_append(
            host_json_array, network_scan.export_host(current_host_id)
        );
    END LOOP;

    -- Final bit get the scan_type back out
    scan_json := json_build_object(
        'pg_id', scan_row.pg_id,
        'hosts', host_json_array,
        'scan_type', scan_row.scan_type,
        'scan_target', scan_row.scan_target
    );

    RETURN scan_json;
END
$$ LANGUAGE plpgsql SECURITY DEFINER;
