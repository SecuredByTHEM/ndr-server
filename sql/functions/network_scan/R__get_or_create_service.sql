-- Services are what are being offered on a port. They should be relatively static
-- unless something changes in the configuration or updates are applied
--
-- Once again we de-duplicate this data so we can also cross-reference these 

CREATE OR REPLACE FUNCTION network_scan.get_or_create_service(
        _name text,
        _method network_scan.service_discovery_method,
        _version text,
        _product text,
        _extrainfo text,
        _tunnel network_scan.tunnel_type,
        _proto network_scan.service_protocol,
        _rpcnum integer,
        _lowver integer,
        _highver integer,
        _hostname text,
        _ostype text,
        _devicetype text,
        _servicefp text
    ) RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    service_id bigint;
BEGIN
    -- The NULL situation here is not what I call a good thing since we also can't
    -- easily put a constraint on the column being fully unique. What we probably need
    -- to do is create a hash of the values, and primary key it so a collision is impossible
    -- ... hopefully. This should be good enough for now though.

    SELECT id INTO service_id FROM network_scan.services WHERE
        name=_name AND
        method=_method AND

        -- All the following comments can be NULL so ...
        version IS NOT DISTINCT FROM version AND
        product IS NOT DISTINCT FROM _product AND
        extrainfo IS NOT DISTINCT FROM _extrainfo AND
        tunnel IS NOT DISTINCT FROM _tunnel AND
        proto IS NOT DISTINCT FROM _proto AND
        rpcnum IS NOT DISTINCT FROM _rpcnum AND
        lowver IS NOT DISTINCT FROM _lowver AND
        highver IS NOT DISTINCT FROM _highver AND
        hostname IS NOT DISTINCT FROM _hostname AND
        ostype IS NOT DISTINCT FROM _ostype AND
        devicetype IS NOT DISTINCT FROM _devicetype AND
        servicefp IS NOT DISTINCT FROM _servicefp;

    -- It's time's like this I miss MySQL's EXTENDED INSERT syntax ...
    IF NOT FOUND THEN 
        INSERT INTO network_scan.services (
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
                servicefp) 
            VALUES (
                _name,
                _method,
                _version,
                _product,
                _extrainfo,
                _tunnel,
                _proto,
                _rpcnum,
                _lowver,
                _highver,
                _hostname,
                _ostype,
                _devicetype,
                _servicefp)
            RETURNING id INTO service_id;
        END IF;

    RETURN service_id;
END
$$;