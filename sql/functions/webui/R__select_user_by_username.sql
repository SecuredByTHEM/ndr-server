-- Selects a user by email address
CREATE OR REPLACE FUNCTION webui.select_user_by_username(_username text) RETURNS SETOF webui.users
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
	RETURN QUERY SELECT * FROM webui.users WHERE username=_username;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'User with username % not found', _username;
	END IF;

	RETURN;
END
$$;
