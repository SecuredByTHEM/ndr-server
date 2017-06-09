--
-- Name: create_host(bigint, inet, macaddr, text, scan_reason, integer, text); Type: FUNCTION; Schema: network_scan; Owner: -
--

CREATE OR REPLACE FUNCTION network_scan.create_host(_scan_id bigint, _ip_address_id bigint, _mac_address_id bigint, _state text, _reason network_scan.scan_reason, _reason_ttl integer) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    host_id bigint;
BEGIN
    INSERT INTO network_scan.hosts (scan_id, ip_address_id, mac_address_id, state, reason, reason_ttl) VALUES
        (_scan_id, _ip_address_id, _mac_address_id, _state, _reason, _reason_ttl) RETURNING id INTO host_id;
    RETURN host_id;
END
$$;
