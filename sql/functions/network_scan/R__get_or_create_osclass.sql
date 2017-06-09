-- OS Classes are a report of what a device may or may not be based on the scan results
--
-- Once again we de-duplicate this data so we can also cross-reference these 

CREATE OR REPLACE FUNCTION network_scan.get_or_create_osclass(
        _vendor text,
        _osgen text,
        _ostype text,
        _osfamily text
    )
    RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    osclass_id bigint;
BEGIN
    SELECT id INTO osclass_id FROM network_scan.osclasses WHERE
        vendor=_vendor AND

        -- More places where NULLs can be a thing
        -- See the comment in get_or_create_service() for more thigns about NULL handling
        osgen IS NOT DISTINCT FROM _osgen AND
        ostype IS NOT DISTINCT FROM _ostype AND
        osfamily IS NOT DISTINCT FROM _osfamily;

    IF NOT FOUND THEN
        INSERT INTO network_scan.osclasses(vendor, osgen, ostype, osfamily)
            VALUES (
                _vendor,
                _osgen,
                _ostype,
                _osfamily
            ) RETURNING id INTO osclass_id;
    END IF;

    RETURN osclass_id;
END
$$;