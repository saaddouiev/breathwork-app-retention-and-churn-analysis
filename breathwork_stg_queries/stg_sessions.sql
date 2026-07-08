CREATE TABLE stg_sessions AS
SELECT
    session_id,
    user_id,
    started_at::TIMESTAMP AS started_at,
    ended_at::TIMESTAMP AS ended_at,
    session_duration_seconds::INT AS session_duration_seconds,
    TRIM(device_type) AS device_type,
    did_complete_content::BOOLEAN AS did_complete_content
FROM breathwork_app_schema.raw_sessions;

SET search_path TO breathwork_app_schema;
ALTER TABLE stg_sessions ADD CONSTRAINT pk_stg_sessions PRIMARY KEY (session_id);
