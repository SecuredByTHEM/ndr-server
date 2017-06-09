--
-- Name: select_contact_by_id(bigint); Type: FUNCTION; Schema: admin; Owner: -
--

CREATE OR REPLACE FUNCTION admin.select_contact_by_id(contact_id bigint) RETURNS SETOF public.contacts
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
	RETURN QUERY SELECT * FROM contacts WHERE id=contact_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Contact with ID % not found', contact_id;
	END IF;

	RETURN;
END
$$;