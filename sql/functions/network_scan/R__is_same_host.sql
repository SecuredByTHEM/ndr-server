-- Test function to determine if two hosts are in fact the same host.

CREATE OR REPLACE FUNCTION network_scan.is_same_host(_host1_id bigint, _host2_id bigint)
    RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    host1_row network_scan.hosts;
    host2_row network_scan.hosts;
BEGIN

    -- The hosts table has a reference to the mac_address and ip_address tables, by comparing these values
    -- to each other, we can determine if we're looking at the same host or not.

    SELECT * FROM network_scan.hosts INTO host1_row WHERE id =_host1_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Host 1 with ID % not found', _host1_id;
    END IF;

    -- And again
    SELECT * FROM network_scan.hosts INTO host2_row WHERE id =_host2_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Host 2 with ID % not found', _host2_id;
    END IF;

    -- Currently, hosts are considered identical if they have the same MAC address. This needs
    -- to be expanded at some point to be somewhat smarter but as a basic building block it
    -- will do

    --RAISE NOTICE 'Host 1 MAC Address ID %', host1_row.mac_address_id;
    --RAISE NOTICE 'Host 2 MAC Address ID %', host2_row.mac_address_id;

    IF host1_row.mac_address_id = host2_row.mac_address_id THEN
        RETURN TRUE;
    END IF;

    -- No match found
    RETURN FALSE;
END
$$;
