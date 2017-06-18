-- Adds additional types to NMAP types in the database

-- Reasons in scans that were previously overlooked.
ALTER TYPE network_scan.scan_reason ADD VALUE 'port-unreach';

-- Add additional scan types
ALTER TYPE network_scan.scan_type ADD VALUE 'ipv6-link-local-discovery';
ALTER TYPE network_scan.scan_type ADD VALUE 'ip-protocol-detection';
ALTER TYPE network_scan.scan_type ADD VALUE 'port-scan';
ALTER TYPE network_scan.scan_type ADD VALUE 'nd-discovery';
