-- Table for holding SNORT traffic information which is cross-referenced against the NMAP
-- IP/MAC addressess

CREATE SCHEMA IF NOT EXISTS snort;

CREATE TABLE snort.traffic_reports (
    id bigint PRIMARY KEY,
    msg_id bigint REFERENCES public.recorder_messages(id), 
    dst bigint REFERENCES network_scan.ip_addresses(id),
    dst_port int,
    src bigint REFERENCES network_scan.ip_addresses(id),
    src_port int,
    eth_src_id bigint REFERENCES network_scan.mac_addresses(id),
    eth_dst_id bigint REFERENCES network_scan.mac_addresses(id),
    proto network_scan.port_protocol,
    rx_packets bigint NOT NULL,
    tx_packets bigint NOT NULL,
    first_seen timestamp without time zone NOT NULL
)