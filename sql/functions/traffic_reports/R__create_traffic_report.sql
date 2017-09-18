-- Creates a traffic report from Tshark Reports

-- Hostnames can be null
CREATE OR REPLACE FUNCTION traffic_report.create_traffic_report(_message_id bigint,
                                                                _protocol network_scan.port_protocol,
                                                                _src inet,
                                                                _src_hostname text,
                                                                _src_port int,
                                                                _dst inet,
                                                                _dst_hostname text,
                                                                _dst_port int,
                                                                _rxpackets bigint,
                                                                _txpackets bigint,
                                                                _start_ts bigint,
                                                                _duration real)
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
    DECLARE
        traffic_log_id bigint;
        src_ip_address_id bigint;
        dst_ip_address_id bigint;
        src_hostname_id bigint := NULL;
        dst_hostname_id bigint := NULL;
    BEGIN
    
        -- For the values that are not NULL, get the IDs for them
        src_ip_address_id := network_scan.get_or_create_ip_address(_src);
        dst_ip_address_id := network_scan.get_or_create_ip_address(_dst);

        -- If we have a hostname, register it and get it's ID
        if _src_hostname != NULL THEN
            src_hostname_id := network_scan.get_or_create_hostname(_src_hostname);
        END IF;

        if _dst_hostname != NULL THEN
            src_hostname_id := network_scan.get_or_create_hostname(_src_hostname);
        END IF;

        -- Strictly speaking we could tie this to network scan ports, but that doesn't make
        -- THAT much sense I think since srcports can be randomized

        INSERT INTO traffic_report.traffic_reports (
            msg_id,
            dst,
            src,
            ethsrc_id,
            ethdst_id,
            proto,
            rxpackets,
            txpackets,
            firstseen
        ) VALUES (
            _message_id,
            dst_ip_address_id,
            src_ip_address_id,
            src_mac_address_id,
            dst_mac_address_id,
            _proto,
            _rxpackets,
            _txpackets,
            TO_TIMESTAMP(_firstseen_ts)
        );

    END;
$$;