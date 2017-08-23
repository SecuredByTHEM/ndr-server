ALTER TABLE recorders DROP COLUMN software_revision;
ALTER TABLE recorders ADD COLUMN image_build_date bigint;
ALTER TABLE recorders ADD COLUMN image_type varchar NOT NULL DEFAULT 'unknown';

CREATE TYPE recorder_files AS ENUM (
    'nmap_config'
);

CREATE SCHEMA IF NOT EXISTS configs;

CREATE TABLE configs.recorder_file_blobs (
    id bigint PRIMARY KEY NOT NULL,
    contents bytea NOT NULL
);

CREATE TABLE configs.recorder_file_versions (
    id bigint PRIMARY KEY NOT NULL,
    recorder_id bigint NOT NULL REFERENCES public.recorders (id),
    file_type recorder_files NOT NULL,
    expected_sha256 varchar(40), -- Both these fields can be NULL since it's POSSIBLE for 
    recorder_sha256 varchar(40), -- for a recorder to have a file without the DB
    file_blob bigint REFERENCES configs.recorder_file_blobs (id)
);
