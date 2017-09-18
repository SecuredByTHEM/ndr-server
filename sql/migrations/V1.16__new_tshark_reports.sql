-- New DB handling stuff is plperlu
CREATE EXTENSION IF NOT EXISTS plperlu;

ALTER TYPE recorder_message_type ADD VALUE 'traffic_report';

CREATE SCHEMA IF NOT EXISTS traffic_report;
GRANT USAGE ON SCHEMA traffic_report TO ndr_ingest;

CREATE TABLE traffic_report.known_internet_hostnames (
    id bigserial NOT NULL PRIMARY KEY,
    ip_id bigint NOT NULL REFERENCES network_scan.ip_addresses(id),
    domain_name text NOT NULL,
    first_seen timestamp without time zone DEFAULT now() NOT NULL,
    most_recently_seen timestamp without time zone DEFAULT now() NOT NULL
);

CREATE TABLE traffic_report.traffic_reports (
    id bigserial NOT NULL PRIMARY KEY,
    msg_id bigint NOT NULL REFERENCES public.recorder_messages(id),
    protocol network_scan.port_protocol NOT NULL,
    src_ip_id bigint NOT NULL REFERENCES network_scan.ip_addresses(id),
    src_hostname_id bigint REFERENCES network_scan.hostnames(id),
    src_port int NOT NULL,
    dst_ip_id bigint NOT NULL REFERENCES network_scan.ip_addresses(id),
    dst_hostname_id bigint REFERENCES network_scan.hostnames(id),
    dst_port int NOT NULL,
    rx_bytes int NOT NULL,
    tx_bytes int NOT NULL,
    start_timestamp timestamp without time zone NOT NULL,
    duration real NOT NULL 
);

CREATE TABLE traffic_report.network_outbound_traffic (
    id bigserial NOT NULL,
    traffic_report_id bigint NOT NULL REFERENCES traffic_report.traffic_reports(id),
    local_ip_id bigint NOT NULL NOT NULL REFERENCES network_scan.ip_addresses(id),
    global_ip_id bigint NOT NULL NOT NULL REFERENCES network_scan.ip_addresses(id),
    geoip_database_version text NOT NULL,
    country_code char(2),
    country_name text,
    region_name text,
    city_name text,
    isp text,
    domain text
);