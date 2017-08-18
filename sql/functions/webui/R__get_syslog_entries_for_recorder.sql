-- Builds an overview of a set of recorders and returns it in JSON format
--
-- Rows are ordered most recent back to front
                                                                 
CREATE OR REPLACE FUNCTION webui.get_syslog_entries_for_recorder(_recorder_ids bigint[],
                                                                 _priorities text[],
                                                                 _offset integer,
                                                                 _limit integer)
    RETURNS SETOF public.flattened_syslog_entries
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    priority_text text;
    actual_priorities public.syslog_priority[];
BEGIN
    -- PostgreSQL's enums remain an unfortunate bastard stepchild. There appears to be no
    -- trivial way get it to take an array of values and treat them as enum values (which
    -- I suppose makes sense due to how enums are implements). There's an argument to making
    -- these enums into a trigger function. So go through and convert the incoming values
    -- from text and build a new array;

    FOREACH priority_text IN ARRAY _priorities
    LOOP
        actual_priorities := array_append(actual_priorities, priority_text::public.syslog_priority);
    END LOOP;

    RETURN QUERY SELECT * FROM public.flattened_syslog_entries WHERE recorder_id = ANY(_recorder_ids)
                 AND priority = ANY(actual_priorities)
                 OFFSET _offset LIMIT _limit;
END
$$;
