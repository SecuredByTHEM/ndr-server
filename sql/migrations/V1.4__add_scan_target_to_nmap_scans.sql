-- Scan target referrs to what was scanned in each scan
ALTER TABLE network_scan.scans ADD COLUMN scan_target cidr;