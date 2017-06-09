-- Hostnames need to be handled on both PTR records and user (A/AAAA) records

CREATE OR REPLACE  FUNCTION network_scan.get_or_create_hostname(_hostname text, _type network_scan.hostname_type) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    hostname_id bigint;
BEGIN
    SELECT id INTO hostname_id FROM network_scan.hostnames WHERE hostname=_hostname AND type=_type;
    IF NOT FOUND THEN
        INSERT INTO network_scan.hostnames(hostname, type) VALUES (_hostname, _type) RETURNING id INTO hostname_id;
    END IF;

    RETURN hostname_id;
END
$$;