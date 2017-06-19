--
-- Name: import_scan(json); Type: FUNCTION; Schema: network_scan; Owner: -
--

CREATE OR REPLACE FUNCTION network_scan.import_scan(_msg_id bigint, _scan_json json) RETURNS bigint AS $$
DECLARE
    scan_id bigint;
	host json;
BEGIN
    -- REMINDER: I dropped the row for connecting the scan to a message

    -- Step 1: Create the top-level scan object
    INSERT INTO network_scan.scans (msg_id, scan_type, scan_target) VALUES (
        _msg_id,
        (_scan_json->>'scan_type')::network_scan.scan_type,
        (_scan_json->>'scan_target')::cidr
    ) RETURNING id INTO scan_id;

    -- Step 2: Create hosts based on the scan; we'll tie them to the baseline later
    FOR host IN SELECT * FROM json_array_elements((_scan_json->>'hosts')::json)
    LOOP
        DECLARE
            host_id bigint;
            hostname json;
            hostname_id bigint;
            port json;
            script_json json;
            osmatch_block json;
            osclass json;
            host_osmatch_id bigint;
            cpe_json json;
            ip_address_id bigint;
            mac_address_id bigint;
        BEGIN
            -- We need to get the MAC address and IP address objects if they already exist in the schema.
            -- We'll always have the IP address, but the MAC address might be MIA if it can't be found

            ip_address_id := network_scan.get_or_create_ip_address(
                _ip_address := (host->>'addr')::inet
            );

            mac_address_id := NULL;
            IF (host->>'mac_address')::macaddr IS NOT NULL THEN
                mac_address_id := network_scan.get_or_create_mac_address(
                    _mac_address := (host->>'mac_address')::macaddr,
                    _vendor := (host->>'vendor')::text
                );
            END IF;

            -- Now we can create the host
            host_id := network_scan.create_host(_scan_id := scan_id,
                                                _ip_address_id := ip_address_id,
                                                _mac_address_id := mac_address_id,
                                                _state := host->>'state',
                                                _reason := (host->>'reason')::network_scan.scan_reason,
                                                _reason_ttl := (host->'reason_ttl')::text::integer);

            -- Import Hostnames
            FOR hostname IN SELECT * FROM json_array_elements((host->>'hostnames')::json)
            LOOP
                hostname_id := network_scan.get_or_create_hostname(
                    _hostname := hostname->>'hostname',
                    _type := (hostname->>'type')::network_scan.hostname_type
                );

                INSERT INTO network_scan.host_hostnames(host_id, hostname_id) VALUES
                    (host_id, hostname_id);
            END LOOP; -- hostname loop

            -- Import port scan results
            FOR port IN SELECT * FROM json_array_elements((host->>'ports')::json)
            LOOP
                DECLARE
                    port_id bigint;
                    service json;
                    service_id bigint;
                    host_port_services_id bigint;
                BEGIN
                    port_id := network_scan.insert_port_status(_host_id := host_id,
                                                               _portid := (port->>'portid')::text::integer,
                                                               _protocol := (port->>'protocol')::network_scan.port_protocol,
                                                               _state := (port->>'state')::network_scan.port_state,
                                                               _reason := (port->>'reason')::network_scan.scan_reason,
                                                               _reason_ttl := (port->'reason_ttl')::text::integer);

                    -- Import the service detection information for this port if it exists
                    IF port->>'service' IS NOT NULL THEN
                        service := port->>'service';
                        service_id := network_scan.get_or_create_service(
                            _name := service->>'name',
                            _method := (service->>'method')::network_scan.service_discovery_method,
                            _version := service->>'version',
                            _product := service->>'product',
                            _extrainfo := service->>'extrainfo',
                            _tunnel := (service->>'tunnel')::network_scan.tunnel_type,
                            _proto := (service->>'proto')::network_scan.service_protocol,
                            _rpcnum := (service->>'rpcnum')::integer,
                            _lowver := (service->>'lowver')::integer,
                            _highver := (service->>'highver')::integer,
                            _hostname := service->>'hostname',
                            _ostype := service->>'ostype',
                            _devicetype := service->>'devicetype',
                            _servicefp := service->>'servicefp');

                        -- And link this to the port
                        INSERT INTO network_scan.host_port_services (host_port_id, service_id, confidence)
                            VALUES (port_id, service_id, (service->>'confidence')::integer)
                            RETURNING id INTO host_port_services_id;

                        -- Load services CPE (if present)
                        IF service->>'cpes' IS NOT NULL THEN
                            FOR cpe_json IN SELECT * FROM json_array_elements((service->>'cpes')::json)
                            LOOP
                                DECLARE
                                    service_cpe_id bigint;
                                    cpe_id bigint;
                                BEGIN
                                    cpe_id := network_scan.get_or_create_cpe(
                                        _cpe := cpe_json::text
                                    );

                                    -- This insert is allowed to fail because the unique constraint 
                                    -- may already indicate the data is already there.
                                    INSERT INTO network_scan.service_cpes(service_id, cpe_id)
                                        VALUES (service_id, cpe_id);
                                    EXCEPTION WHEN unique_violation THEN
                                        RAISE NOTICE 'Skipping CPE % due to already being in place', cpe_json;
                                END;
                            END LOOP;
                        END IF;
                    END IF;

                    -- Load script output (if any). Data is deduplicated on read in
                    IF port->>'script_output' IS NOT NULL THEN
                        FOR script_json IN SELECT * FROM json_array_elements((port->>'script_output')::json)
                        LOOP
                            DECLARE
                                script_output_id bigint;
                            BEGIN
                                script_output_id := network_scan.get_or_create_script_output(
                                    _script_name := script_json->>'script_name',
                                    _output := script_json->>'output',
                                    _elements := (script_json->>'elements')::jsonb
                                );

                                INSERT INTO network_scan.host_port_script_outputs (host_port_id, script_output_id) VALUES
                                    (host_port_services_id, script_output_id);
                            END;
                        END LOOP;
                    END IF; -- script_output
                END; -- port
            END LOOP; -- port loop
            
            -- Handle inserting all the OS class information
            IF host->>'osmatches' IS NOT NULL THEN
                FOR osmatch_block IN SELECT * FROM json_array_elements((host->>'osmatches')::json)
                LOOP
                    DECLARE
                        osmatch_id bigint;
                    BEGIN
                        -- OSMatches are followed by the classifications of what an OS can be
                        osmatch_id := network_scan.get_or_create_osmatch(
                            _name := osmatch_block->>'name'
                        );
                        INSERT INTO network_scan.host_osmatches (host_id, osmatch_id, accuracy) 
                            VALUES (host_id, osmatch_id, (osmatch_block->>'accuracy')::smallint)
                            RETURNING id INTO host_osmatch_id;
                    END;

                    -- OSclasses are a "more indepth" version of osmatches of what classification
                    -- a device is. They can also have CPEs assoicated with them.

                    IF osmatch_block->>'osclasses' IS NOT NULL THEN
                        FOR osclass IN SELECT * FROM json_array_elements((osmatch_block->>'osclasses')::json)
                        LOOP
                            DECLARE
                                osclass_id bigint;
                                cpe_id bigint;
                            BEGIN
                                osclass_id := network_scan.get_or_create_osclass(
                                    _vendor := osclass->>'vendor',
                                    _osgen := osclass->>'osgen',
                                    _ostype := osclass->>'ostype',
                                    _osfamily := osclass->>'osfamily'
                                );

                                -- Now attach the osclass to the match with the accuracy score
                                INSERT INTO network_scan.host_osmatches_osclasses 
                                    (host_osmatch_id, osclass_id, accuracy)
                                    VALUES (
                                        host_osmatch_id,
                                        osclass_id,
                                        (osclass->>'accuracy')::integer
                                    );

                                -- And now we get to do CPEs again
                                IF osclass->>'cpes' IS NOT NULL THEN
                                    FOR cpe_json IN SELECT * FROM json_array_elements((osclass->>'cpes')::json)
                                    LOOP
                                        DECLARE
                                            cpe_id bigint;
                                        BEGIN
                                            cpe_id := network_scan.get_or_create_cpe(
                                                _cpe := cpe_json::text
                                            );
                                            INSERT INTO network_scan.osclass_cpes(osclass_id, cpe_id)
                                                VALUES (osclass_id, cpe_id);
                                            EXCEPTION WHEN unique_violation THEN
                                                RAISE NOTICE 'Skipping CPE % due to already being in place', cpe_json;
                                        END; -- cpes DELCARE
                                    END LOOP; -- cpes loop
                                END IF; -- cpes if
                            END; -- osclasses DECLARE
                        END LOOP; -- osclasses loop
                    END IF; -- osclass if
                END LOOP;
            END IF; -- osmatches
            
        END; -- host
    END LOOP;

    RETURN scan_id;
END
$$ LANGUAGE plpgsql SECURITY DEFINER;
