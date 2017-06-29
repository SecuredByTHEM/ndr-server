-- This has to be its own file for flyway migrations.

-- SNORT uses ICMP as as it's own port protocol. We'll add it to the existing port protocols.

ALTER TYPE network_scan.port_protocol ADD VALUE 'icmp';
