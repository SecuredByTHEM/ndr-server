-- Vendor information is only updated when seen on a new scan result. We should probably import the MAC vendor
-- information independently and update the table as scan results get updated. To be thought about ...

CREATE OR REPLACE FUNCTION network_scan.get_or_create_mac_address(_mac_address macaddr, _vendor text) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    mac_addr_id bigint;
    vendor_str text;
BEGIN
    SELECT id, vendor INTO mac_addr_id, vendor_str FROM network_scan.mac_addresses WHERE mac_address=_mac_address;
    IF NOT FOUND THEN
        -- MACs are dynamically added as they're seen across scans
        INSERT INTO network_scan.mac_addresses(mac_address, vendor) VALUES (_mac_address, _vendor) RETURNING id INTO mac_addr_id;
        RETURN mac_addr_id;
    END IF;

    -- If the vendor is NOT NULL, and the vendor in the table is, we'll update it
    IF _vendor IS NOT NULL AND vendor_str != _vendor THEN
        UPDATE network_scan.mac_addresses SET vendor=_vendor WHERE id=mac_addr_id;
    END IF;

    RETURN mac_addr_id;
END
$$;