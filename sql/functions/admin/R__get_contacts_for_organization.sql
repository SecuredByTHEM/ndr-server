--
-- Name: get_contacts_for_organization(bigint); Type: FUNCTION; Schema: admin; Owner: -
--

CREATE OR REPLACE FUNCTION admin.get_contacts_for_organization(_org_id bigint) RETURNS SETOF public.contacts
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
	RETURN QUERY SELECT * FROM contacts WHERE contacts.org_id=_org_id;
END
$$;