-- Forgot to grant usage permission
GRANT USAGE ON SCHEMA configs TO ndr_ingest;

-- So we can use hashing functions in the database
CREATE EXTENSION IF NOT EXISTS pgcrypto;
ALTER TABLE configs.recorder_file_versions ADD CONSTRAINT rfv_rec_id_file_type UNIQUE(recorder_id, file_type);
ALTER TABLE configs.recorder_file_versions RENAME COLUMN file_blob TO file_blob_id;

-- Because I'm an IDIOT
CREATE SEQUENCE configs.recorder_file_versions_pk_seq;
ALTER TABLE configs.recorder_file_versions ALTER COLUMN id SET DEFAULT nextval('configs.recorder_file_versions_pk_seq'::regclass);

CREATE SEQUENCE configs.recorder_file_blobs_pk_seq;
ALTER TABLE configs.recorder_file_blobs ALTER COLUMN id SET DEFAULT nextval('configs.recorder_file_blobs_pk_seq'::regclass);

ALTER TABLE configs.recorder_file_versions ALTER COLUMN expected_sha256 TYPE char(64);
ALTER TABLE configs.recorder_file_versions ALTER COLUMN recorder_sha256 TYPE char(64);
