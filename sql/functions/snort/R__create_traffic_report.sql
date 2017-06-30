-- Creates a traffic report for SNORT

-- Many of the fields can be NULL, so keep that in mind while reading this code.

CREATE OR REPLACE FUNCTION snort.create_traffic_report(_message_id bigint,
                                                       _src inet,
                                                       _srcport int,
                                                       _dst inet,
                                                       _dstport int,
                                                       _ethsrc macaddr,
                                                       _ethdst macaddr,
                                                       _proto network_scan.port_protocol,
                                                       _rxpackets bigint,
                                                       _txpackets bigint,
                                                       _firstseen_ts numeric)
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
    DECLARE
        traffic_log_id bigint;
        src_ip_address_id bigint;
        dst_ip_address_id bigint;
        src_mac_address_id bigint;
        dst_mac_address_id bigint;
    BEGIN
    
        -- For the values that are not NULL, get the IDs for them
        src_ip_address_id := network_scan.get_or_create_ip_address(_src);
        dst_ip_address_id := network_scan.get_or_create_ip_address(_dst);

        src_mac_address_id := network_scan.get_or_create_mac_address(_ethsrc, NULL);
        dst_mac_address_id := network_scan.get_or_create_mac_address(_ethdst, NULL);

        -- Technically, we could create port identifiers, but for the moment, I'm going to keep these seperate
        -- as the network scan doesn't handle source/destination port information.

        INSERT INTO snort.traffic_reports (
            msg_id,
            dst,
            dstport,
            src,
            srcport,
            ethsrc_id,
            ethdst_id,
            proto,
            rxpackets,
            txpackets,
            firstseen
        ) VALUES (
            _message_id,
            dst_ip_address_id,
            _dstport,
            src_ip_address_id,
            _srcport,
            src_mac_address_id,
            dst_mac_address_id,
            _proto,
            _rxpackets,
            _txpackets,
            TO_TIMESTAMP(_firstseen_ts)
        );

    END;
$$;