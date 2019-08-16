-- Create
-- #+NAME: raw_audit_events

CREATE UNLOGGED TABLE raw_audit_events (
  -- id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  -- ingested_at timestamp DEFAULT CURRENT_TIMESTAMP,
  bucket text,
  job text,
  audit_id text NOT NULL,
  stage text NOT NULL,
  event_verb text NOT NULL,
  request_uri text NOT NULL,
  operation_id text,
  data jsonb NOT NULL
);

-- Index
-- #+NAME: index the raw_audit_events

-- CREATE INDEX idx_audit_events_primary          ON raw_audit_events (bucket, job, audit_id, stage);
-- ALTER TABLE raw_audit_events add primary key using index idx_audit_events_primary;
CREATE INDEX idx_audit_events_jsonb_ops        ON raw_audit_events USING GIN (data jsonb_ops);
CREATE INDEX idx_audit_events_jsonb_path_jobs  ON raw_audit_events USING GIN (data jsonb_path_ops);