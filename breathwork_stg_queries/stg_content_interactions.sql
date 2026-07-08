CREATE TABLE stg_content_interactions AS
SELECT
    interaction_id,
    user_id,
    session_id,
    content_id,
    content_title,
    difficulty,
    content_type,
    started_at::TIMESTAMP AS started_at,
    completed::BOOLEAN AS completed,
    CASE WHEN completion_pct::NUMERIC > 1 THEN NULL ELSE ROUND((completion_pct::NUMERIC * 100), 2) END
    AS completion_pct,
    duration_seconds::INT AS duration_seconds,
    is_first_session::BOOLEAN AS is_first_session
FROM breathwork_app_schema.raw_content_interactions;

SET search_path TO breathwork_app_schema;
ALTER TABLE stg_content_interactions ADD CONSTRAINT pk_stg_content_interactions PRIMARY KEY (interaction_id);
