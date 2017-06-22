-- Provides the latest scans for each recorder on the network, grouped 
CREATE OR REPLACE VIEW network_scan.latest_scans AS
    SELECT DISTINCT ON (site_id, nss.scan_type, nss.scan_target) nss.id, s.id as site_id, r.id as recorder_id, 
        nss.scan_type, rm.generated_at, nss.scan_target
    FROM network_scan.scans AS nss
        LEFT JOIN recorder_messages AS rm ON (nss.msg_id=rm.id)
        LEFT JOIN recorders AS r ON (rm.recorder_id=r.id)
        LEFT JOIN sites AS s ON (s.id=r.site_id)
        ORDER BY site_id, nss.scan_type, nss.scan_target, generated_at DESC;
