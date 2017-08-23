ALTER TABLE recorders DROP COLUMN software_revision;
ALTER TABLE recorders ADD COLUMN image_build_date bigint;
ALTER TABLE recorders ADD COLUMN image_type varchar NOT NULL DEFAULT 'unknown';
