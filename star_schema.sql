SET search_path TO breathwork_app_schema;

-- Drop and rebuild every time this script runs, so it's safe to
-- re-run without manual cleanup. CASCADE also drops the foreign
-- keys defined at the bottom of this file.
DROP TABLE IF EXISTS fact_subscription CASCADE;
DROP TABLE IF EXISTS fact_engagement CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;
DROP TABLE IF EXISTS dim_content CASCADE;
DROP TABLE IF EXISTS dim_user CASCADE;

-- ============================================================
-- dim_user — grain: one row per user_id
-- ============================================================
CREATE TABLE dim_user AS
SELECT
    user_id,
    created_at::TIMESTAMP AS created_at,
    COALESCE(NULLIF(acquisition_channel, ''), 'unknown') AS acquisition_channel,
    device_type,
    country,
    NULLIF(age, '')::INT AS age,
    trial_start_date::DATE AS trial_start_date,
    trial_end_date::DATE AS trial_end_date,
    converted_to_paid::BOOLEAN AS converted_to_paid,
    converted_at::TIMESTAMP AS converted_at
FROM raw_users;

ALTER TABLE dim_user ADD CONSTRAINT pk_dim_user PRIMARY KEY (user_id);

-- ============================================================
-- dim_content — grain: one row per content_id
-- ============================================================
CREATE TABLE dim_content AS
SELECT
    content_id,
    content_type,
    content_title,
    difficulty,
    typical_duration_seconds::INT AS typical_duration_seconds
FROM raw_content_catalog;

ALTER TABLE dim_content ADD CONSTRAINT pk_dim_content PRIMARY KEY (content_id);

-- ============================================================
-- dim_date — grain: one row per calendar date
-- ============================================================
CREATE TABLE dim_date AS
SELECT
    d::date AS date_key,
    EXTRACT(YEAR FROM d)::INT AS year,
    EXTRACT(MONTH FROM d)::INT AS month,
    TO_CHAR(d, 'Month') AS month_name,
    EXTRACT(DAY FROM d)::INT AS day,
    EXTRACT(DOW FROM d)::INT AS day_of_week,
    EXTRACT(DOW FROM d) IN (0, 6) AS is_weekend
FROM generate_series('2022-01-01'::date, '2027-12-31'::date, '1 day') AS d;

ALTER TABLE dim_date ADD CONSTRAINT pk_dim_date PRIMARY KEY (date_key);

-- ============================================================
-- fact_engagement — grain: one row per content interaction.
-- Sessions with no interaction (~1.4% of sessions) are kept via
-- LEFT JOIN as placeholder rows so activation metrics (first
-- session date, sessions in trial) still count every session.
-- No PK: a session can have more than one interaction, so no
-- single column is unique per row.
-- ============================================================
CREATE TABLE fact_engagement AS
SELECT
    ci.interaction_id,
    s.session_id,
    s.user_id,
    ci.content_id,
    s.started_at::date AS date_key,
    s.started_at::TIMESTAMP AS session_started_at,
    s.ended_at::TIMESTAMP AS session_ended_at,
    s.session_duration_seconds::INT AS session_duration_seconds,
    TRIM(s.device_type) AS session_device_type,
    s.did_complete_content::BOOLEAN AS did_complete_content,
    ci.started_at::TIMESTAMP AS interaction_started_at,
    ci.completed::BOOLEAN AS interaction_completed,
    CASE WHEN ci.completion_pct::NUMERIC > 1 THEN NULL
         ELSE ROUND((ci.completion_pct::NUMERIC * 100), 2) END AS completion_pct,
    ci.duration_seconds::INT AS interaction_duration_seconds,
    ci.is_first_session::BOOLEAN AS is_first_session
FROM raw_sessions s
LEFT JOIN raw_content_interactions ci ON ci.session_id = s.session_id;

-- Session-level columns (session_duration_seconds, session_started_at)
-- repeat across every interaction row for that session — dedupe on
-- session_id before averaging/counting at the session level.

-- ============================================================
-- fact_subscription — grain: one row per subscription_id
-- (not user_id — ~11% of users have held more than one
-- subscription over time).
-- ============================================================
CREATE TABLE fact_subscription AS
SELECT
    sub.subscription_id,
    sub.user_id,
    sub.plan,
    TRIM(sub.status) AS status,
    NULLIF(sub.started_at, '')::TIMESTAMP::date AS started_date_key,
    sub.cancelled_at::TIMESTAMP::date AS cancelled_date_key,
    COALESCE(NULLIF(sub.cancellation_reason, ''), 'unknown') AS cancellation_reason,
    NULLIF(sub.billing_amount, '')::DECIMAL AS billing_amount,
    sub.billing_currency,
    sub.reactivated::BOOLEAN AS reactivated,
    COALESCE(pay.total_revenue, 0) AS total_revenue
FROM raw_subscriptions sub
LEFT JOIN (
    SELECT subscription_id, SUM(amount::NUMERIC(10,2)) AS total_revenue
    FROM raw_payments
    GROUP BY subscription_id
    -- sums ALL payments regardless of status; add a status filter
    -- above if failed/refunded payments shouldn't count as revenue
) pay ON pay.subscription_id = sub.subscription_id;

ALTER TABLE fact_subscription ADD CONSTRAINT pk_fact_subscription PRIMARY KEY (subscription_id);

-- ============================================================
-- Foreign keys — needed so DataGrip's diagram tool draws the
-- relationships. Query joins already work without these; this
-- just makes the star shape visible in the ERD.
-- ============================================================
ALTER TABLE fact_engagement ADD CONSTRAINT fk_engagement_user
    FOREIGN KEY (user_id) REFERENCES dim_user (user_id);
ALTER TABLE fact_engagement ADD CONSTRAINT fk_engagement_content
    FOREIGN KEY (content_id) REFERENCES dim_content (content_id);
ALTER TABLE fact_engagement ADD CONSTRAINT fk_engagement_date
    FOREIGN KEY (date_key) REFERENCES dim_date (date_key);

ALTER TABLE fact_subscription ADD CONSTRAINT fk_subscription_user
    FOREIGN KEY (user_id) REFERENCES dim_user (user_id);
ALTER TABLE fact_subscription ADD CONSTRAINT fk_subscription_started_date
    FOREIGN KEY (started_date_key) REFERENCES dim_date (date_key);
ALTER TABLE fact_subscription ADD CONSTRAINT fk_subscription_cancelled_date
    FOREIGN KEY (cancelled_date_key) REFERENCES dim_date (date_key);