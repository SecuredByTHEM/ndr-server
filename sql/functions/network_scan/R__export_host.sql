-- Exports a host in JSON format
CREATE OR REPLACE FUNCTION network_scan.export_host(_host_id bigint) RETURNS json AS $$
DECLARE
    hostname_json_array json[];
    port_json_array json[];
    osmatches_json_array json[];
    host_address network_scan.flattened_host_addresses;
    hostname_row network_scan.flattened_host_hostnames;
    port_row network_scan.flattened_host_ports;
    service_row network_scan.flattened_port_services;
    service_cpes_row network_scan.flattened_service_cpes;
    osmatch_row network_scan.flattened_host_osmatches;
    osclass_row network_scan.flattened_host_osmatches_osclasses;
    osclass_cpe_row network_scan.flattened_osclass_cpes;
    script_output_row network_scan.flattened_script_output;
BEGIN
    SELECT * INTO host_address FROM network_scan.flattened_host_addresses WHERE host_id=_host_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Host % Not Found!', _host_id;
    END IF;

    -- Grab hostnames, if any
    FOR hostname_row IN SELECT * FROM network_scan.flattened_host_hostnames WHERE host_id=host_address.host_id
    LOOP
        hostname_json_array := array_append(
            hostname_json_array,
                json_build_object(
                'hostname', hostname_row.hostname,
                'type', hostname_row.type
            )
        );
    END LOOP; -- hostname loop


    -- Initialize a default if stuff isn't there'
    port_json_array := NULL;

    -- Grab the port data
    FOR port_row IN SELECT * FROM network_scan.flattened_host_ports WHERE host_id=host_address.host_id
    LOOP
        DECLARE
            service_json json;
            script_output_array json[];
            cpes_array json[];
        BEGIN

            -- Grab the service information and append it
            service_json := NULL;
            SELECT * INTO service_row FROM network_scan.flattened_port_services WHERE host_port_id=port_row.host_port_id;
            IF FOUND THEN
                -- Grabs the CPEs
                FOR service_cpes_row IN SELECT * FROM network_scan.flattened_service_cpes WHERE service_id=service_row.service_id
                LOOP
                    cpes_array := array_append(cpes_array, service_cpes_row.cpe::json);
                END LOOP;

                service_json := json_build_object(
                    'name', service_row.name,
                    'confidence', service_row.confidence,
                    'method', service_row.method,
                    'version', service_row.version,
                    'product', service_row.product,
                    'extrainfo', service_row.extrainfo,
                    'tunnel', service_row.tunnel,
                    'proto', service_row.proto,
                    'rpcnum', service_row.rpcnum,
                    'lowver', service_row.lowver,
                    'highver', service_row.highver,
                    'hostname', service_row.hostname,
                    'ostype', service_row.ostype,
                    'devicetype', service_row.devicetype,
                    'servicefp', service_row.servicefp,
                    'cpes', cpes_array
                );
            END IF;

            -- Now we handle the script output
            FOR script_output_row IN SELECT * FROM network_scan.flattened_script_output WHERE host_port_id=port_row.host_port_id
            LOOP
                script_output_array := array_append(script_output_array, json_build_object(
                    'script_name', script_output_row.script_name,
                    'output', script_output_row.output,
                    'elements', script_output_row.elements
                ));
            END LOOP;

            -- If we have service information, we need to grab that and append it
            port_json_array := array_append(port_json_array, json_build_object(
                'portid', port_row.portid,
                'protocol', port_row.protocol,
                'state', port_row.state,
                'reason', port_row.reason,
                'reason_ttl', port_row.reason_ttl,
                'service', service_json,
                'script_output', script_output_array
            ));
        END;
    END LOOP;

    -- Now we need to sort the OS detection voodoo
    FOR osmatch_row IN SELECT * FROM network_scan.flattened_host_osmatches WHERE host_id=host_address.host_id
    LOOP
        DECLARE
            osclasses_json_array json[];
            cpes_array json[];
        BEGIN
            -- For some scans, we won't have osmatch information
            IF NOT FOUND THEN
                osmatches_json_array := NULL;
                EXIT;
            END IF;

            -- OSClasses exist under osmatches (and ALSO have CPEs)
            FOR osclass_row IN SELECT * FROM network_scan.flattened_host_osmatches_osclasses WHERE host_osmatch_id=osmatch_row.host_osmatch_id
            LOOP
                -- Grabs the CPEs
                FOR osclass_cpe_row IN SELECT * FROM network_scan.flattened_osclass_cpes WHERE osclass_id=osclass_row.osclass_id
                LOOP
                    cpes_array := array_append(cpes_array, osclass_cpe_row.cpe::json);
                END LOOP;

                osclasses_json_array := array_append(osclasses_json_array, json_build_object(
                    'accuracy', osclass_row.accuracy,
                    'vendor', osclass_row.vendor,
                    'osgen', osclass_row.osgen,
                    'ostype', osclass_row.ostype,
                    'osfamily', osclass_row.osfamily,
                    'cpes', cpes_array
                ));

            END LOOP;
            osmatches_json_array := array_append(osmatches_json_array, json_build_object(
                'name', osmatch_row.name,
                'accuracy', osmatch_row.accuracy,
                'osclasses', osclasses_json_array
            ));
        END;
    END LOOP;

    -- Now that we have all the bits, assembly the host object
    RETURN json_build_object(
        'pg_id', host_address.host_id,
        'addr', host_address.ip_address,
        'mac_address', host_address.mac_address,
        'vendor', host_address.vendor,
        'state', host_address.state,
        'reason', host_address.reason,
        'reason_ttl', host_address.reason_ttl,
        'hostname', hostname_json_array,
        'ports', port_json_array,
        'osmatches', osmatches_json_array
    );

END
$$ LANGUAGE plpgsql SECURITY DEFINER;
