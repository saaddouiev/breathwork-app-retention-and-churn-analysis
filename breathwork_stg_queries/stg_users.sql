CREATE TABLE stg_users AS
SELECT
    user_id,
    created_at::TIMESTAMP AS created_at,
    COALESCE(NULLIF(acquisition_channel, ''), 'unknown') AS acquisition_channel,
    device_type,
    country,
    NULLIF(age, '')::INT AS age,
    plan_type,
    trial_start_date::DATE AS trial_start_date,
    trial_end_date::DATE AS trial_end_date,
    converted_to_paid::BOOLEAN AS converted_to_paid,
    converted_at::TIMESTAMP AS converted_at
FROM breathwork_app_schema.raw_users;

SET search_path TO breathwork_app_schema;
ALTER TABLE stg_users ADD CONSTRAINT pk_stg_users PRIMARY KEY (user_id);
