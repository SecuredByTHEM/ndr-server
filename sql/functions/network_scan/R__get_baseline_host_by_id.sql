CREATE OR REPLACE FUNCTION network_scan.get_baseline_host_by_id(_baseline_id bigint)
    RETURNS SETOF network_scan.flattened_baseline_hosts_with_attributes
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY SELECT * FROM network_scan.flattened_baseline_hosts_with_attributes
        WHERE id=_baseline_id;
    
    IF NOT FOUND THEN
		RAISE EXCEPTION 'Baseline Host ID % not found', _baseline_id;
	END IF;

	RETURN;
END
$$;
