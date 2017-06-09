--
-- Name: insert_port_status(bigint, integer, port_protocol, port_state, scan_reason, integer); Type: FUNCTION; Schema: network_scan; Owner: -
--

CREATE OR REPLACE FUNCTION network_scan.insert_port_status(
        _host_id bigint,
        _portid integer,
        _protocol network_scan.port_protocol,
        _state network_scan.port_state,
        _reason network_scan.scan_reason,
        _reason_ttl integer)
    RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    port_id bigint;
    port_status_id bigint;
BEGIN
    -- Port scans are broken up into two parts. First is the port identifer, which lives in the ports
    -- table, and is just the port number + protocol. We dynamically create ports as we see them in
    -- scan results. Ports are attached to hosts via a many-to-many relation with additional metadata
    -- such as port state (open, filtered, etc). If a port is not listed, it shall be assumed to be
    -- closed

    port_id := network_scan.get_or_create_port(_portid := _portid,
                                               _protocol := _protocol);
    INSERT INTO network_scan.host_port_status(host_id, port_id, state, reason, reason_ttl) VALUES
        (_host_id, port_id, _state, _reason, _reason_ttl) RETURNING id INTO port_status_id;
    RETURN port_status_id;
END
$$;
