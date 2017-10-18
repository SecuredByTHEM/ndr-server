CREATE OR REPLACE FUNCTION network_scan.set_baseline_host_human_name(_baseline_host_id bigint,
                                                                     _human_name text)
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    UPDATE network_scan.baseline_hosts SET human_name=_human_name
        WHERE id=_baseline_host_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Baseline host % not found!', _baseline_host_id;
    END IF;
END
$$;