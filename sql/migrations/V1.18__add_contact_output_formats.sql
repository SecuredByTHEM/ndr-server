CREATE TYPE contact_output_formats AS ENUM (
    'zip',
    'csv',
    'inline'
);

ALTER TABLE contacts ADD COLUMN output_format contact_output_formats NOT NULL DEFAULT 'csv';
