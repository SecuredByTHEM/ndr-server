-- GeoIP information is seperated into a seperate table for ease of cross-referencing
-- and using aggrative functions.

--    country_code char(2),
--    country_name text,
--    region_name text,
--    city_name text,
--    isp text,
--    domain text

CREATE OR REPLACE FUNCTION traffic_report.get_or_create_geoip_info_set(
        _country_code char(2),
        _country_name text,
        _region_name text,
        _city_name text,
        _isp text,
        _domain text
    )
    RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    geoip_row_id bigint;
BEGIN
    -- Try to retrieve the row if it already exists
    SELECT id INTO geoip_row_id FROM traffic_report.geoip_information WHERE
        -- Embrace NULLs due to third party data sets
        country_code IS NOT DISTINCT FROM _country_code AND
        country_name IS NOT DISTINCT FROM _country_name AND
        region_name IS NOT DISTINCT FROM _region_name AND
        city_name IS NOT DISTINCT FROM _city_name AND
        isp IS NOT DISTINCT FROM _isp AND
        domain IS NOT DISTINCT FROM _domain;

    IF NOT FOUND THEN
        INSERT INTO traffic_report.geoip_information(
            country_code,
            country_name,
            region_name,
            city_name,
            isp,
            domain)
            VALUES (
                _country_code,
                _country_name,
                _region_name,
                _city_name,
                _isp,
                _domain
            ) RETURNING id INTO geoip_row_id;
    END IF;

    RETURN geoip_row_id;
END
$$;
