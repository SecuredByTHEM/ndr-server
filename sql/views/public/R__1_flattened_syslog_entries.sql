CREATE OR REPLACE VIEW public.flattened_syslog_entries AS
    SELECT sm.*, sp.syslog_program AS program FROM syslog_messages AS sm
        LEFT JOIN syslog_programs AS sp ON (sp.id=sm.program_id)
        ORDER BY sm.id DESC;