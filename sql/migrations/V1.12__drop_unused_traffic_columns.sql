-- Traffic report changes not to report port info for the time being

ALTER TABLE snort.traffic_reports DROP dstport;
ALTER TABLE snort.traffic_reports DROP srcport;

-- Drop the traffic report function
DROP FUNCTION IF EXISTS snort.create_traffic_report(bigint, inet, integer, inet, integer, macaddr, macaddr, network_scan.port_protocol, bigint, bigint, numeric);