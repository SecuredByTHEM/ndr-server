-- Selects a user by ID number
CREATE FUNCTION webui.select_user_by_id(_user_id bigint) RETURNS SETOF webui.users
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
	RETURN QUERY SELECT * FROM webui.users WHERE id=_user_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'User with ID % not found', _user_id;
	END IF;

	RETURN;
END
$$;
