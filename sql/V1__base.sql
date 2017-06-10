CREATE USER ndr_ingest;

CREATE SCHEMA IF NOT EXISTS network_scan;
CREATE SCHEMA IF NOT EXISTS ingest;
CREATE SCHEMA IF NOT EXISTS admin;

GRANT USAGE ON SCHEMA ingest TO ndr_ingest;
GRANT USAGE ON SCHEMA admin TO ndr_ingest;
GRANT USAGE ON SCHEMA network_scan TO ndr_ingest;

--
-- Name: contact_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE contact_type AS ENUM (
    'email'
);


--
-- Name: recorder_message_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE recorder_message_type AS ENUM (
    'status',
    'syslog_upload',
    'test_alert',
    'nmap_scan'
);


--
-- Name: syslog_facility; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE syslog_facility AS ENUM (
    'kern',
    'user',
    'mail',
    'daemon',
    'auth',
    'syslog',
    'lpr',
    'news',
    'uucp',
    'cron',
    'authpriv',
    'console',
    'solaris-cron',
    'local0',
    'local1',
    'local2',
    'local3',
    'local4',
    'local5',
    'local6',
    'local7'
);


--
-- Name: TYPE syslog_facility; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TYPE syslog_facility IS 'Enumeration of known syslog facility logging types';


--
-- Name: syslog_priority; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE syslog_priority AS ENUM (
    'emerg',
    'alert',
    'crit',
    'err',
    'warning',
    'notice',
    'info',
    'debug'
);


--
-- Name: TYPE syslog_priority; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TYPE syslog_priority IS 'Syslog priority fields';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE contacts (
    id bigint NOT NULL,
    org_id bigint,
    method contact_type,
    value character varying
);


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE organizations (
    id bigint NOT NULL,
    name character varying NOT NULL
);


--
-- Name: sites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sites (
    id bigint NOT NULL,
    org_id bigint NOT NULL,
    name character varying NOT NULL
);


--
-- Name: recorders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE recorders (
    id bigint NOT NULL,
    site_id bigint NOT NULL,
    human_name character varying NOT NULL,
    hostname character varying NOT NULL,
    enlisted_at timestamp without time zone DEFAULT now() NOT NULL,
    last_seen timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contacts_id_seq OWNED BY contacts.id;


--
-- Name: organization_org_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE organization_org_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organization_org_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE organization_org_id_seq OWNED BY organizations.id;


--
-- Name: recorder_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE recorder_messages (
    id bigint NOT NULL,
    recorder_id bigint,
    message_type recorder_message_type,
    generated_at timestamp without time zone,
    received_at timestamp without time zone
);


--
-- Name: recorder_messages_rm_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE recorder_messages_rm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recorder_messages_rm_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE recorder_messages_rm_id_seq OWNED BY recorder_messages.id;


--
-- Name: recorders_recorder_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE recorders_recorder_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recorders_recorder_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE recorders_recorder_id_seq OWNED BY recorders.id;


--
-- Name: site_site_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE site_site_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: site_site_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE site_site_id_seq OWNED BY sites.id;


--
-- Name: syslog_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE syslog_messages (
    id bigint NOT NULL,
    recorder_id bigint NOT NULL,
    program_id bigint NOT NULL,
    pid bigint,
    facility syslog_facility NOT NULL,
    priority syslog_priority NOT NULL,
    message text NOT NULL,
    recorder_message_id bigint,
    host character varying,
    logged_at timestamp without time zone
);


--
-- Name: syslog_messages_syslog_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE syslog_messages_syslog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: syslog_messages_syslog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE syslog_messages_syslog_id_seq OWNED BY syslog_messages.id;


--
-- Name: syslog_programs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE syslog_programs (
    id bigint NOT NULL,
    syslog_program character varying
);


--
-- Name: syslog_programs_sprg_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE syslog_programs_sprg_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: syslog_programs_sprg_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE syslog_programs_sprg_id_seq OWNED BY syslog_programs.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contacts ALTER COLUMN id SET DEFAULT nextval('contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY organizations ALTER COLUMN id SET DEFAULT nextval('organization_org_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY recorder_messages ALTER COLUMN id SET DEFAULT nextval('recorder_messages_rm_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY recorders ALTER COLUMN id SET DEFAULT nextval('recorders_recorder_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sites ALTER COLUMN id SET DEFAULT nextval('site_site_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY syslog_messages ALTER COLUMN id SET DEFAULT nextval('syslog_messages_syslog_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY syslog_programs ALTER COLUMN id SET DEFAULT nextval('syslog_programs_sprg_id_seq'::regclass);


--
-- Name: contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: organization_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY organizations
    ADD CONSTRAINT organization_pkey PRIMARY KEY (id);


--
-- Name: organizations_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY organizations
    ADD CONSTRAINT organizations_name_key UNIQUE (name);


--
-- Name: recorder_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recorder_messages
    ADD CONSTRAINT recorder_messages_pkey PRIMARY KEY (id);


--
-- Name: recorders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recorders
    ADD CONSTRAINT recorders_pkey PRIMARY KEY (id);


--
-- Name: recorders_uucp_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recorders
    ADD CONSTRAINT recorders_uucp_name_key UNIQUE (hostname);


--
-- Name: site_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sites
    ADD CONSTRAINT site_pkey PRIMARY KEY (id);


--
-- Name: syslog_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY syslog_messages
    ADD CONSTRAINT syslog_events_pkey PRIMARY KEY (id);


--
-- Name: syslog_programs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY syslog_programs
    ADD CONSTRAINT syslog_programs_pkey PRIMARY KEY (id);


--
-- Name: syslog_programs_program_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY syslog_programs
    ADD CONSTRAINT syslog_programs_program_key UNIQUE (syslog_program);


--
-- Name: contacts_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contacts
    ADD CONSTRAINT contacts_org_id_fkey FOREIGN KEY (org_id) REFERENCES organizations(id);


--
-- Name: recorder_messages_recorder_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recorder_messages
    ADD CONSTRAINT recorder_messages_recorder_id_fkey FOREIGN KEY (recorder_id) REFERENCES recorders(id);


--
-- Name: recorders_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recorders
    ADD CONSTRAINT recorders_site_id_fkey FOREIGN KEY (site_id) REFERENCES sites(id);


--
-- Name: site_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sites
    ADD CONSTRAINT site_org_id_fkey FOREIGN KEY (org_id) REFERENCES organizations(id);


--
-- Name: syslog_events_recorder_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY syslog_messages
    ADD CONSTRAINT syslog_events_recorder_id_fkey FOREIGN KEY (recorder_id) REFERENCES recorders(id);


--
-- Name: syslog_messages_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY syslog_messages
    ADD CONSTRAINT syslog_messages_program_id_fkey FOREIGN KEY (program_id) REFERENCES syslog_programs(id);


--
-- Name: syslog_messages_recorder_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY syslog_messages
    ADD CONSTRAINT syslog_messages_recorder_message_id_fkey FOREIGN KEY (recorder_message_id) REFERENCES recorder_messages(id) ON DELETE CASCADE;



SET search_path = network_scan, public;

--
-- Name: hostname_type; Type: TYPE; Schema: network_scan; Owner: -
--

CREATE TYPE network_scan.hostname_type AS ENUM (
    'user',
    'PTR'
);


--
-- Name: TYPE hostname_type; Type: COMMENT; Schema: network_scan; Owner: -
--

COMMENT ON TYPE network_scan.hostname_type IS 'Represents the hostname types as nmap reports them. We might add additional metadata if we try to get additional DNS information out of them at a future date.';


--
-- Name: port_protocol; Type: TYPE; Schema: network_scan; Owner: -
--

CREATE TYPE network_scan.port_protocol AS ENUM (
    'ip',
    'tcp',
    'udp',
    'sctp'
);


--
-- Name: port_state; Type: TYPE; Schema: network_scan; Owner: -
--

CREATE TYPE network_scan.port_state AS ENUM (
    'open',
    'filtered',
    'unfiltered',
    'closed',
    'open|filtered',
    'closed|filtered',
    'unknown'
);


--
-- Name: scan_reason; Type: TYPE; Schema: network_scan; Owner: -
--

CREATE TYPE network_scan.scan_reason AS ENUM (
    'reset',
    'conn-refused',
    'syn-ack',
    'split-handshake-syn',
    'udp-response',
    'proto-response',
    'perm-denied',
    'net-unreach',
    'host-unreach',
    'proto-unreach',
    'echo-reply',
    'dest-unreach',
    'source-quench',
    'net-prohibited',
    'host-prohibited',
    'admin-prohibited',
    'time-exceeded',
    'timestamp-reply',
    'no-ipid-change',
    'arp-response',
    'nd-response',
    'tcp-response',
    'no-response',
    'init-ack',
    'abort',
    'localhost-response',
    'script-set',
    'unknown-response',
    'user-set',
    'no-route',
    'beyond-scope',
    'reject-route',
    'param-problem'
);


--
-- Name: TYPE scan_reason; Type: COMMENT; Schema: network_scan; Owner: -
--

COMMENT ON TYPE network_scan.scan_reason IS 'This list is redrieved from nmap portreasons.cc which is also used for things like host detection';


--
-- Name: service_discovery_method; Type: TYPE; Schema: network_scan; Owner: -
--

CREATE TYPE network_scan.service_discovery_method AS ENUM (
    'table',
    'probed'
);


--
-- Name: service_protocol; Type: TYPE; Schema: network_scan; Owner: -
--

CREATE TYPE network_scan.service_protocol AS ENUM (
    'rpc'
);


--
-- Name: TYPE service_protocol; Type: COMMENT; Schema: network_scan; Owner: -
--

COMMENT ON TYPE network_scan.service_protocol IS 'This type is slightly misleading. It''s using by nmap to describe if a service is an interface for something-in-something. Currently the only supported value of rpc';


--
-- Name: tunnel_type; Type: TYPE; Schema: network_scan; Owner: -
--

CREATE TYPE network_scan.tunnel_type AS ENUM (
    'ssl'
);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: cpes; Type: TABLE; Schema: network_scan; Owner: -
--

CREATE TABLE cpes (
    id bigint NOT NULL,
    cpe character varying
);


--
-- Name: cpes_id_seq; Type: SEQUENCE; Schema: network_scan; Owner: -
--

CREATE SEQUENCE cpes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cpes_id_seq; Type: SEQUENCE OWNED BY; Schema: network_scan; Owner: -
--

ALTER SEQUENCE cpes_id_seq OWNED BY cpes.id;


--
-- Name: host_hostnames; Type: TABLE; Schema: network_scan; Owner: -
--

CREATE TABLE host_hostnames (
    id bigint NOT NULL,
    host_id bigint NOT NULL,
    hostname_id bigint NOT NULL
);


--
-- Name: host_osclasses; Type: TABLE; Schema: network_scan; Owner: -
--

CREATE TABLE host_osclasses (
    id bigint NOT NULL,
    host_id bigint NOT NULL,
    osclass_id bigint NOT NULL
);


--
-- Name: host_osclasses_id_seq; Type: SEQUENCE; Schema: network_scan; Owner: -
--

CREATE SEQUENCE host_osclasses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: host_osclasses_id_seq; Type: SEQUENCE OWNED BY; Schema: network_scan; Owner: -
--

ALTER SEQUENCE host_osclasses_id_seq OWNED BY host_osclasses.id;


--
-- Name: host_port_status; Type: TABLE; Schema: network_scan; Owner: -
--

CREATE TABLE host_port_status (
    id bigint NOT NULL,
    host_id bigint NOT NULL,
    port_id bigint NOT NULL,
    state network_scan.port_state NOT NULL,
    reason network_scan.scan_reason NOT NULL,
    reason_ttl integer
);


--
-- Name: host_port_status_id_seq; Type: SEQUENCE; Schema: network_scan; Owner: -
--

CREATE SEQUENCE host_port_status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: host_port_status_id_seq; Type: SEQUENCE OWNED BY; Schema: network_scan; Owner: -
--

ALTER SEQUENCE host_port_status_id_seq OWNED BY host_port_status.id;


--
-- Name: hostnames; Type: TABLE; Schema: network_scan; Owner: -
--

CREATE TABLE hostnames (
    id bigint NOT NULL,
    hostname character varying NOT NULL,
    type network_scan.hostname_type
);


--
-- Name: hostnames_id_seq; Type: SEQUENCE; Schema: network_scan; Owner: -
--

CREATE SEQUENCE hostnames_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hostnames_id_seq; Type: SEQUENCE OWNED BY; Schema: network_scan; Owner: -
--

ALTER SEQUENCE hostnames_id_seq OWNED BY hostnames.id;


--
-- Name: hosts; Type: TABLE; Schema: network_scan; Owner: -
--

CREATE TABLE hosts (
    id bigint NOT NULL,
    scan_id bigint NOT NULL,
    addr inet NOT NULL,
    mac_addr macaddr,
    state character varying NOT NULL,
    reason network_scan.scan_reason NOT NULL,
    reason_ttl integer NOT NULL,
    vendor character varying
);


--
-- Name: hosts_id_seq; Type: SEQUENCE; Schema: network_scan; Owner: -
--

CREATE SEQUENCE hosts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hosts_id_seq; Type: SEQUENCE OWNED BY; Schema: network_scan; Owner: -
--

ALTER SEQUENCE hosts_id_seq OWNED BY hosts.id;


--
-- Name: osclass_cpes; Type: TABLE; Schema: network_scan; Owner: -
--

CREATE TABLE osclass_cpes (
    id bigint NOT NULL,
    osclass_id bigint NOT NULL,
    cpe_id bigint NOT NULL
);


--
-- Name: osclass_cpes_id_seq; Type: SEQUENCE; Schema: network_scan; Owner: -
--

CREATE SEQUENCE osclass_cpes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: osclass_cpes_id_seq; Type: SEQUENCE OWNED BY; Schema: network_scan; Owner: -
--

ALTER SEQUENCE osclass_cpes_id_seq OWNED BY osclass_cpes.id;


--
-- Name: osclass_osmatchs; Type: TABLE; Schema: network_scan; Owner: -
--

CREATE TABLE osclass_osmatchs (
    id bigint NOT NULL,
    osmatch_id bigint NOT NULL,
    osclass_id bigint NOT NULL
);


--
-- Name: osclass_osmatchs_id_seq; Type: SEQUENCE; Schema: network_scan; Owner: -
--

CREATE SEQUENCE osclass_osmatchs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: osclass_osmatchs_id_seq; Type: SEQUENCE OWNED BY; Schema: network_scan; Owner: -
--

ALTER SEQUENCE osclass_osmatchs_id_seq OWNED BY osclass_osmatchs.id;


--
-- Name: osclasses; Type: TABLE; Schema: network_scan; Owner: -
--

CREATE TABLE osclasses (
    id bigint NOT NULL,
    vendor character varying NOT NULL,
    osgen character varying,
    ostype character varying,
    accuracy integer NOT NULL,
    osfamily character varying
);


--
-- Name: osclasses_id_seq; Type: SEQUENCE; Schema: network_scan; Owner: -
--

CREATE SEQUENCE osclasses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: osclasses_id_seq; Type: SEQUENCE OWNED BY; Schema: network_scan; Owner: -
--

ALTER SEQUENCE osclasses_id_seq OWNED BY osclasses.id;


--
-- Name: osmatches; Type: TABLE; Schema: network_scan; Owner: -
--

CREATE TABLE osmatches (
    id bigint NOT NULL,
    name character varying NOT NULL,
    accuracy integer NOT NULL
);


--
-- Name: osmatches_id_seq; Type: SEQUENCE; Schema: network_scan; Owner: -
--

CREATE SEQUENCE osmatches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: osmatches_id_seq; Type: SEQUENCE OWNED BY; Schema: network_scan; Owner: -
--

ALTER SEQUENCE osmatches_id_seq OWNED BY osmatches.id;


--
-- Name: ports; Type: TABLE; Schema: network_scan; Owner: -
--

CREATE TABLE ports (
    id bigint NOT NULL,
    portid integer NOT NULL,
    protocol network_scan.port_protocol NOT NULL
);


--
-- Name: ports_id_seq; Type: SEQUENCE; Schema: network_scan; Owner: -
--

CREATE SEQUENCE ports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ports_id_seq; Type: SEQUENCE OWNED BY; Schema: network_scan; Owner: -
--

ALTER SEQUENCE ports_id_seq OWNED BY ports.id;


--
-- Name: scans; Type: TABLE; Schema: network_scan; Owner: -
--

CREATE TABLE scans (
    id bigint NOT NULL
);


--
-- Name: scans_id_seq; Type: SEQUENCE; Schema: network_scan; Owner: -
--

CREATE SEQUENCE scans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scans_id_seq; Type: SEQUENCE OWNED BY; Schema: network_scan; Owner: -
--

ALTER SEQUENCE scans_id_seq OWNED BY scans.id;


--
-- Name: service_cpes; Type: TABLE; Schema: network_scan; Owner: -
--

CREATE TABLE service_cpes (
    id bigint NOT NULL,
    service_id bigint,
    cpe_id bigint
);


--
-- Name: service_cpes_id_seq; Type: SEQUENCE; Schema: network_scan; Owner: -
--

CREATE SEQUENCE service_cpes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: service_cpes_id_seq; Type: SEQUENCE OWNED BY; Schema: network_scan; Owner: -
--

ALTER SEQUENCE service_cpes_id_seq OWNED BY service_cpes.id;


--
-- Name: services; Type: TABLE; Schema: network_scan; Owner: -
--

CREATE TABLE services (
    id bigint NOT NULL,
    name character varying NOT NULL,
    confidence integer NOT NULL,
    method network_scan.service_discovery_method NOT NULL,
    version character varying,
    product character varying,
    extrainfo character varying,
    tunnel network_scan.tunnel_type,
    proto network_scan.service_protocol,
    rpcnum integer,
    lowver integer,
    highver integer,
    hostname character varying,
    ostype character varying,
    devicetype character varying,
    servicefp character varying
);


--
-- Name: services_id_seq; Type: SEQUENCE; Schema: network_scan; Owner: -
--

CREATE SEQUENCE services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: network_scan; Owner: -
--

ALTER SEQUENCE services_id_seq OWNED BY services.id;


--
-- Name: id; Type: DEFAULT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY cpes ALTER COLUMN id SET DEFAULT nextval('cpes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY host_osclasses ALTER COLUMN id SET DEFAULT nextval('host_osclasses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY host_port_status ALTER COLUMN id SET DEFAULT nextval('host_port_status_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY hostnames ALTER COLUMN id SET DEFAULT nextval('hostnames_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY hosts ALTER COLUMN id SET DEFAULT nextval('hosts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY osclass_cpes ALTER COLUMN id SET DEFAULT nextval('osclass_cpes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY osclass_osmatchs ALTER COLUMN id SET DEFAULT nextval('osclass_osmatchs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY osclasses ALTER COLUMN id SET DEFAULT nextval('osclasses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY osmatches ALTER COLUMN id SET DEFAULT nextval('osmatches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY ports ALTER COLUMN id SET DEFAULT nextval('ports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY scans ALTER COLUMN id SET DEFAULT nextval('scans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY service_cpes ALTER COLUMN id SET DEFAULT nextval('service_cpes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY services ALTER COLUMN id SET DEFAULT nextval('services_id_seq'::regclass);


--
-- Name: cpes_pkey; Type: CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY cpes
    ADD CONSTRAINT cpes_pkey PRIMARY KEY (id);


--
-- Name: host_osclasses_pkey; Type: CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY host_osclasses
    ADD CONSTRAINT host_osclasses_pkey PRIMARY KEY (id);


--
-- Name: host_port_status_pkey; Type: CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY host_port_status
    ADD CONSTRAINT host_port_status_pkey PRIMARY KEY (id);


--
-- Name: hostnames_pkey; Type: CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY hostnames
    ADD CONSTRAINT hostnames_pkey PRIMARY KEY (id);


--
-- Name: hosts_pkey; Type: CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY hosts
    ADD CONSTRAINT hosts_pkey PRIMARY KEY (id);


--
-- Name: hosts_to_hostnames_pkey; Type: CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY host_hostnames
    ADD CONSTRAINT hosts_to_hostnames_pkey PRIMARY KEY (id);


--
-- Name: osclass_cpes_pkey; Type: CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY osclass_cpes
    ADD CONSTRAINT osclass_cpes_pkey PRIMARY KEY (id);


--
-- Name: osclass_osmatchs_pkey; Type: CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY osclass_osmatchs
    ADD CONSTRAINT osclass_osmatchs_pkey PRIMARY KEY (id);


--
-- Name: osclasses_pkey; Type: CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY osclasses
    ADD CONSTRAINT osclasses_pkey PRIMARY KEY (id);


--
-- Name: osmatches_pkey; Type: CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY osmatches
    ADD CONSTRAINT osmatches_pkey PRIMARY KEY (id);


--
-- Name: ports_pkey; Type: CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY ports
    ADD CONSTRAINT ports_pkey PRIMARY KEY (id);


--
-- Name: scans_pkey; Type: CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY scans
    ADD CONSTRAINT scans_pkey PRIMARY KEY (id);


--
-- Name: service_cpes_pkey; Type: CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY service_cpes
    ADD CONSTRAINT service_cpes_pkey PRIMARY KEY (id);


--
-- Name: service_cpes_service_id_cpe_id_key; Type: CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY service_cpes
    ADD CONSTRAINT service_cpes_service_id_cpe_id_key UNIQUE (service_id, cpe_id);


--
-- Name: services_pkey; Type: CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: host_osclasses_host_id_fkey; Type: FK CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY host_osclasses
    ADD CONSTRAINT host_osclasses_host_id_fkey FOREIGN KEY (host_id) REFERENCES hosts(id);


--
-- Name: host_osclasses_osclass_id_fkey; Type: FK CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY host_osclasses
    ADD CONSTRAINT host_osclasses_osclass_id_fkey FOREIGN KEY (osclass_id) REFERENCES osclasses(id);

--
-- Name: host_port_status_host_id_fkey; Type: FK CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY host_port_status
    ADD CONSTRAINT host_port_status_host_id_fkey FOREIGN KEY (host_id) REFERENCES hosts(id);


--
-- Name: host_port_status_port_id_fkey; Type: FK CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY host_port_status
    ADD CONSTRAINT host_port_status_port_id_fkey FOREIGN KEY (port_id) REFERENCES ports(id);


--
-- Name: hosts_scan_id_fkey; Type: FK CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY hosts
    ADD CONSTRAINT hosts_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES scans(id) ON DELETE CASCADE;


--
-- Name: hosts_to_hostnames_host_id_fkey; Type: FK CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY host_hostnames
    ADD CONSTRAINT hosts_to_hostnames_host_id_fkey FOREIGN KEY (host_id) REFERENCES hosts(id);


--
-- Name: hosts_to_hostnames_hostname_id_fkey; Type: FK CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY host_hostnames
    ADD CONSTRAINT hosts_to_hostnames_hostname_id_fkey FOREIGN KEY (hostname_id) REFERENCES hostnames(id);


--
-- Name: osclass_cpes_cpe_id_fkey; Type: FK CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY osclass_cpes
    ADD CONSTRAINT osclass_cpes_cpe_id_fkey FOREIGN KEY (cpe_id) REFERENCES cpes(id);


--
-- Name: osclass_cpes_osclass_id_fkey; Type: FK CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY osclass_cpes
    ADD CONSTRAINT osclass_cpes_osclass_id_fkey FOREIGN KEY (osclass_id) REFERENCES osclasses(id);


--
-- Name: osclass_osmatchs_osclass_id_fkey; Type: FK CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY osclass_osmatchs
    ADD CONSTRAINT osclass_osmatchs_osclass_id_fkey FOREIGN KEY (osclass_id) REFERENCES osclasses(id);


--
-- Name: osclass_osmatchs_osmatch_id_fkey; Type: FK CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY osclass_osmatchs
    ADD CONSTRAINT osclass_osmatchs_osmatch_id_fkey FOREIGN KEY (osmatch_id) REFERENCES osmatches(id);


--
-- Name: service_cpes_cpe_id_fkey; Type: FK CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY service_cpes
    ADD CONSTRAINT service_cpes_cpe_id_fkey FOREIGN KEY (cpe_id) REFERENCES cpes(id);


--
-- Name: service_cpes_service_id_fkey; Type: FK CONSTRAINT; Schema: network_scan; Owner: -
--

ALTER TABLE ONLY service_cpes
    ADD CONSTRAINT service_cpes_service_id_fkey FOREIGN KEY (service_id) REFERENCES services(id);
