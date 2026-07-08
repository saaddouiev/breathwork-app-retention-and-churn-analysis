CREATE TABLE stg_content_catalog AS
SELECT
    content_id,
    content_type,
    content_title,
    difficulty,
    typical_duration_seconds::INT AS typical_duration_seconds
FROM breathwork_app_schema.raw_content_catalog;

SET search_path TO breathwork_app_schema;
ALTER TABLE stg_content_catalog ADD CONSTRAINT pk_stg_content_catalog PRIMARY KEY (content_id);
