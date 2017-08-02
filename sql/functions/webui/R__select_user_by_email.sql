-- Selects a user by email address
CREATE FUNCTION webui.select_user_by_email(_email text) RETURNS SETOF webui.users
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
	RETURN QUERY SELECT * FROM webui.users WHERE email=_email;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'User with email % not found', _email;
	END IF;

	RETURN;
END
$$;
