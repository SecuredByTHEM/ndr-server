CREATE SCHEMA IF NOT EXISTS webui;
GRANT USAGE ON SCHEMA webui TO ndr_ingest;

CREATE TABLE webui.users (
    id bigserial PRIMARY KEY NOT NULL,
    username text NOT NULL UNIQUE,
    email text NOT NULL UNIQUE,
    password_hash text NOT NULL,
    real_name text NOT NULL,
    created_at timestamp without time zone NOT NULL DEFAULT NOW(),
    active boolean NOT NULL default 'f',
    superadmin boolean NOT NULL default 'f'
);
