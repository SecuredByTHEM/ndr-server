CREATE OR REPLACE FUNCTION network_scan.get_or_create_script_output(
        _script_name text,
        _output text,
        _elements jsonb
    )
    RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    script_output_id bigint;
BEGIN
    SELECT id INTO script_output_id FROM network_scan.script_outputs
        WHERE script_name=_script_name AND
              output=_output AND
              elements=_elements;

    IF NOT FOUND THEN
        INSERT INTO network_scan.script_outputs(script_name, output, elements) VALUES (_script_name, _output, _elements) RETURNING id INTO script_output_id;
    END IF;

    RETURN script_output_id;
END
$$;