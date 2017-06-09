-- OS Matches are a report of what a device may or may not be based on the scan results
--
-- We de-duplicate this data so we can also cross-reference these 

CREATE OR REPLACE FUNCTION network_scan.get_or_create_osmatch(
        _name text
    )
    RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    osmatch_id bigint;
BEGIN
    SELECT id INTO osmatch_id FROM network_scan.osmatches WHERE name=_name;
    IF NOT FOUND THEN
        INSERT INTO network_scan.osmatches(name) VALUES (_name) RETURNING id INTO osmatch_id;
    END IF;

    RETURN osmatch_id;
END
$$;