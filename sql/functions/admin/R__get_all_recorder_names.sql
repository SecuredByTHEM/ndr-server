CREATE OR REPLACE FUNCTION admin.get_all_recorder_names() 
    RETURNS TABLE (hostname varchar)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
	RETURN QUERY SELECT r.hostname FROM public.recorders AS r;
END
$$;