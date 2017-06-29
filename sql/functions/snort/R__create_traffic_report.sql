-- Creates a traffic report for SNORT

-- Many of the fields can be NULL, so keep that in mind while reading this code.

CREATE OR REPLACE FUNCTION snort.create_traffic_report(_message_id bigint,
                                                       _dst inet,
                                                       _dst_port int,
                                                       _src inet,
                                                       _src_port int,
                                                       _eth_src macaddr,
                                                       _eth_dst macaddr,
                                                       _proto network_scan.port_protocol,
                                                       _rx_packets bigint,
                                                       _tx_packets bigint,
                                                       _firstseen_ts bigint)
    RETURNS bigint
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

        src_mac_address_id := network_scan.get_or_create_mac_address(_eth_src);
        dst_mac_address_id := network_scan.get_or_create_mac_address(_eth_dst);

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
            first_seen
        ) VALUES (
            _message_id,
            dst_ip_address_id,
            _dst_port,
            src_ip_address_id,
            _src_port,
            src_mac_address_id,
            dst_mac_address_id,
            _proto,
            _rx_packets,
            _tx_packets,
            TO_TIMESTAMP(_firstseen_ts)
        ) RETURNING id AS traffic_log_id;

        RETURN traffic_log_id;
    END;
$$;