--
-- Name: get_or_create_port(integer, port_protocol); Type: FUNCTION; Schema: network_scan; Owner: -
--

CREATE OR REPLACE  FUNCTION network_scan.get_or_create_port(_portid integer, _protocol network_scan.port_protocol) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    port_id bigint;
BEGIN
    SELECT id INTO port_id FROM network_scan.ports WHERE portid=_portid AND protocol=_protocol;
    IF NOT FOUND THEN
        -- Ports are dynamically added as they're seen across scans
        INSERT INTO network_scan.ports(portid, protocol) VALUES (_portid, _protocol) RETURNING id INTO port_id;
    END IF;

    RETURN port_id;
END
$$;