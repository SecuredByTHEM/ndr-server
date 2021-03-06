-- Registers a traffic report hostname as a known publicly resolvable hostname. This function
-- works on a traffic_report.hostname id, and updates the hostname seen date if it doesn't already
-- exist

CREATE OR REPLACE FUNCTION traffic_report.register_internet_hostname_from_tr(_traffic_report_id bigint,
                                                                            _ip_id bigint,
                                                                            _hostname_id bigint
    ) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    int_hostname_id bigint;
BEGIN
    -- First, determine if we've seen this hostname before
    SELECT id INTO int_hostname_id FROM traffic_report.known_internet_hostnames WHERE id=_hostname_id;
    IF NOT FOUND THEN
        -- Nope
        INSERT INTO traffic_report.known_internet_hostnames (ip_id, hostname_id) VALUES 
            (_ip_id, _hostname_id) RETURNING id INTO int_hostname_id;
    ELSE
        -- We have seen it, update the last seen date and call it good
        UPDATE traffic_report.known_internet_hostnames SET last_seen = NOW() WHERE id=int_hostname_id;
    END IF;

    -- Link the domain entry to the traffic report
    INSERT INTO traffic_report.traffic_report_internet_hostnames (traffic_report_id, internet_hostname_id)
        VALUES (_traffic_report_id, int_hostname_id);
END
$$;