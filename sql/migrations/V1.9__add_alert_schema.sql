CREATE SCHEMA IF NOT EXISTS alert;
GRANT USAGE ON SCHEMA alert TO ndr_ingest;

CREATE TABLE alert.alert_msg_history (
    id bigserial PRIMARY KEY NOT NULL,
    msg_id bigint NOT NULL REFERENCES recorder_messages(id),
    program text NOT NULL,
    message text NOT NULL
)
