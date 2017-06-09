-- Strictly speaking, we should probably parse CPEs into their component parts, but we're
-- not there yet

CREATE OR REPLACE  FUNCTION network_scan.get_or_create_cpe(_cpe text) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    cpe_id bigint;
BEGIN
    SELECT id INTO cpe_id FROM network_scan.cpes WHERE cpe=_cpe;
    IF NOT FOUND THEN
        -- Ports are dynamically added as they're seen across scans
        INSERT INTO network_scan.cpes(cpe) VALUES (_cpe) RETURNING id INTO cpe_id;
    END IF;

    RETURN cpe_id;
END
$$;