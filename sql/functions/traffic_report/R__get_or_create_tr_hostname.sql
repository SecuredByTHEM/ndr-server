-- Hostnames need to be handled on both PTR records and user (A/AAAA) records

CREATE OR REPLACE  FUNCTION traffic_report.get_or_create_tr_hostname(_hostname text) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    hostname_id bigint;
BEGIN
    SELECT id INTO hostname_id FROM traffic_report.seen_hostnames WHERE hostname=_hostname;
    IF NOT FOUND THEN
        INSERT INTO traffic_report.seen_hostnames(hostname) VALUES (_hostname) RETURNING id INTO hostname_id;
    END IF;

    RETURN hostname_id;
END
$$;