-- IP addresses will appear in multiple scans from different vendors, but that's acceptable
-- because the IP address here just exists as an identifer for Xrefing purposes

CREATE OR REPLACE  FUNCTION network_scan.get_or_create_ip_address(_ip_address inet) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    ip_address_id bigint;
BEGIN
    SELECT id INTO ip_address_id FROM network_scan.ip_addresses WHERE ip_address=_ip_address;
    IF NOT FOUND THEN
        INSERT INTO network_scan.ip_addresses(ip_address) VALUES (_ip_address) RETURNING id INTO ip_address_id;
    END IF;

    RETURN ip_address_id;
END
$$;