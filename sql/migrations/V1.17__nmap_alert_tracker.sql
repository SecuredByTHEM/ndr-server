-- Tracks unknown hosts
CREATE TABLE alert.network_scan_alert_tracker(
    id bigserial PRIMARY KEY NOT NULL,
    site_id bigint NOT NULL REFERENCES public.sites(id),
    host_id bigint NOT NULL REFERENCES network_scan.hosts(id),
    generated_at timestamp without time zone DEFAULT now() NOT NULL,
    last_seen timestamp without time zone DEFAULT now() NOT NULL,
    alerted_at timestamp without time zone, -- can be NULL if never alerted
    UNIQUE (site_id, host_id)
);
