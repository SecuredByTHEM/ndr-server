-- Create assoication between ports and services

CREATE TABLE network_scan.port_services
(
  id bigserial NOT NULL,
  port_id bigint NOT NULL,
  service_id bigint NOT NULL,
  CONSTRAINT port_services_pkey PRIMARY KEY (id),
  CONSTRAINT port_services_port_id_fkey FOREIGN KEY (port_id)
      REFERENCES network_scan.host_port_status (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT port_services_service_id_fkey FOREIGN KEY (service_id)
      REFERENCES network_scan.services (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT port_services_port_id_service_id_key UNIQUE (port_id, service_id)
);

-- Store script output. Because the script output is essentially semi-structured,
-- we'll take the parts we *can* use, and kick the rest into a jsonb table. We have
-- to store this on a per-scan run (connected to port_status) because script output
-- can change from run to run and requires special processing

CREATE TABLE network_scan.script_outputs
(
    id bigserial NOT NULL PRIMARY KEY,
    host_port_id bigint NOT NULL REFERENCES network_scan.port_services (id),
    script_name text NOT NULL,
    output text NOT NULL,
    elements jsonb NOT NULL
);

-- OSMatches are independent on names, but accuracy needs to be handled at the JOIN level
CREATE TABLE network_scan.host_osmatches
(
    id bigserial NOT NULL PRIMARY KEY,
    host_id bigint NOT NULL REFERENCES network_scan.hosts (id),
    osmatch_id bigint NOT NULL REFERENCES network_scan.osmatches (id),
    accuracy smallint NOT NULL
);

ALTER TABLE network_scan.osmatches DROP accuracy;
ALTER TABLE network_scan.osmatches ADD CONSTRAINT host_osclasses_key UNIQUE(name);

DROP TABLE network_scan.osclass_osmatchs;
CREATE TABLE network_scan.host_osmatches_osclasses
(
    id bigserial NOT NULL PRIMARY KEY,
    host_osmatch_id bigint NOT NULL REFERENCES network_scan.host_osmatches(id),
    osclass_id bigint NOT NULL REFERENCES network_scan.osclasses(id),
    accuracy smallint NOT NULL,
    UNIQUE (host_osmatch_id, osclass_id)
);

ALTER TABLE network_scan.osclasses DROP accuracy;
ALTER TABLE network_scan.osclass_cpes ADD CONSTRAINT osclass_cpe_key UNIQUE(osclass_id, cpe_id);

ALTER TABLE network_scan.hosts DROP mac_addr;
ALTER TABLE network_scan.hosts DROP addr;

-- Mac addresses and IPs can be seen by snort, they have to be seperate from the host
-- entires (we can cross-reference them later)

-- Network scans can have various types of types
CREATE TYPE network_scan.scan_type AS ENUM
(
    'service-discovery'
);

CREATE TABLE network_scan.mac_addresses 
(
    id bigserial NOT NULL PRIMARY KEY,
    mac_address macaddr NULL NULL,
    vendor text
);

CREATE TABLE network_scan.ip_addresses
(
    id bigserial NOT NULL PRIMARY KEY,
    ip_address inet
);

CREATE TABLE network_scan.baseline_hosts
(
    id bigserial NOT NULL PRIMARY KEY,
    site_id bigint NOT NULL REFERENCES sites(id),
    host_id bigint NOT NULL REFERENCES network_scan.hosts(id),
    scan_type network_scan.scan_type NOT NULL,
    UNIQUE (host_id)
    -- Needs a CHECK constraint that the host scan matches
);

ALTER TABLE network_scan.scans ADD scan_type network_scan.scan_type NOT NULL;
ALTER TABLE network_scan.hosts ADD mac_address_id bigint REFERENCES network_scan.mac_addresses(id);
ALTER TABLE network_scan.hosts ADD ip_address_id bigint REFERENCES network_scan.ip_addresses(id);

-- Fix broken table

DROP TABLE network_scan.host_hostnames;
CREATE TABLE network_scan.host_hostnames (
    id bigserial NOT NULL PRIMARY KEY,
    host_id bigint NOT NULL REFERENCES network_scan.hosts(id),
    hostname_id bigint NOT NULL REFERENCES network_scan.hostnames(id)
);

-- Rename the port services table 
ALTER TABLE network_scan.port_services RENAME TO host_port_services;
ALTER TABLE network_scan.host_port_services RENAME COLUMN port_id TO host_port_id;
ALTER TABLE network_scan.host_port_services ADD confidence integer NOT NULL;
ALTER TABLE network_scan.services DROP confidence;

-- Add new constraint on port services
ALTER TABLE network_scan.services ADD CONSTRAINT all_columns_unique UNIQUE (
  name,
  method,
  version,
  product,
  extrainfo,
  tunnel,
  proto,
  rpcnum,
  lowver,
  highver,
  hostname,
  ostype,
  devicetype,
  servicefp);

-- Add missing NOT NULL constraints
ALTER TABLE network_scan.service_cpes ALTER service_id SET NOT NULL;
ALTER TABLE network_scan.service_cpes ALTER cpe_id SET NOT NULL;

-- De-duplicate script output
ALTER TABLE network_scan.script_outputs DROP host_port_id;
CREATE TABLE network_scan.host_port_script_outputs (
    id bigserial NOT NULL PRIMARY KEY,
    host_port_id bigint NOT NULL REFERENCES network_scan.host_port_services(id),
    script_output_id bigint NOT NULL REFERENCES network_scan.script_outputs(id),
    UNIQUE (host_port_id, script_output_id)
);

-- Add message ID column to the database
ALTER TABLE network_scan.scans ADD msg_id bigint REFERENCES public.recorder_messages(id);

-- Drop NOT NULL constraint on script outut
ALTER TABLE network_scan.script_outputs ALTER elements DROP NOT NULL;