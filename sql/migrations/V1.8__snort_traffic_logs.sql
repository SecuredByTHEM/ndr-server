-- Table for holding SNORT traffic information which is cross-referenced against the NMAP
-- IP/MAC addressess

CREATE SCHEMA IF NOT EXISTS snort;
GRANT USAGE ON SCHEMA snort TO ndr_ingest;

CREATE TABLE snort.traffic_reports (
    id bigserial PRIMARY KEY,
    msg_id bigint REFERENCES public.recorder_messages(id), 
    dst bigint REFERENCES network_scan.ip_addresses(id),
    dstport int,
    src bigint REFERENCES network_scan.ip_addresses(id),
    srcport int,
    ethsrc_id bigint REFERENCES network_scan.mac_addresses(id),
    ethdst_id bigint REFERENCES network_scan.mac_addresses(id),
    proto network_scan.port_protocol,
    rxpackets bigint NOT NULL,
    txpackets bigint NOT NULL,
    firstseen timestamp without time zone NOT NULL
)