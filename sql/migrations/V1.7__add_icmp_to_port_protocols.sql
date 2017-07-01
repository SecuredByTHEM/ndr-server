-- This has to be its own file for flyway migrations.

-- SNORT uses ICMP as as it's own port protocol. We'll add it to the existing port protocols.

ALTER TYPE network_scan.port_protocol ADD VALUE 'icmp';

-- And snort_traffic to the message types
ALTER TYPE recorder_message_type ADD VALUE 'snort_traffic';