SET SEARCH_PATH TO breathwork_app_schema;

CREATE VIEW mart_engagement AS
SELECT
    ci.user_id,
    ci.interaction_id,
    ci.session_id,
    ci.started_at,
    ci.duration_seconds,
    ci.content_title,
    ci.difficulty,
    ci.completed,
    ci.completion_pct,
    ci.is_first_session,
    u.plan_type,
    u.acquisition_channel,
    u.age,
    u.country,
    u.device_type
FROM breathwork_app_schema.stg_content_interactions ci
LEFT JOIN breathwork_app_schema.stg_users u ON ci.user_id = u.user_id;

-- Engagement for Churned Users
SELECT
    DATE_TRUNC('week', e.started_at) AS weeks,
    ROUND(COUNT(DISTINCT e.session_id) / NULLIF(COUNT(DISTINCT e.user_id), 0), 2) AS avg_sessions_per_user,
    ROUND(AVG(completion_pct), 2) as avg_completion_pct,
    ROUND(AVG(duration_seconds), 0) AS avg_session_time
FROM mart_engagement e
JOIN mart_churn c ON e.user_id = c.user_id
WHERE status = 'cancelled'
GROUP BY 1;

-- Retention Cohort
WITH user_cohort AS(
    SELECT
        user_id,
        DATE_TRUNC('week', created_at) AS cohort_week
    FROM mart_user_activation
),
user_activity AS(
    SELECT
        user_id,
        DATE_TRUNC('week', started_at) AS activity_week
    FROM mart_engagement
),
cohort_activity AS(
    SELECT
        uc.user_id,
        uc.cohort_week,
        ua.activity_week,
        EXTRACT(DAY FROM (ua.activity_week - uc.cohort_week )) / 7 AS weeks_since_signup
    FROM user_cohort uc
    JOIN user_activity ua ON uc.user_id = ua.user_id
)
SELECT
    cohort_week,
    COUNT(DISTINCT CASE WHEN weeks_since_signup = 0 THEN user_id END) AS week0,
    COUNT(DISTINCT CASE WHEN weeks_since_signup = 1 THEN user_id END) AS week1,
    COUNT(DISTINCT CASE WHEN weeks_since_signup = 4 THEN user_id END) AS week4,
    COUNT(DISTINCT CASE WHEN weeks_since_signup = 12 THEN user_id END) AS month3,
    COUNT(DISTINCT CASE WHEN weeks_since_signup = 24 THEN user_id END) AS month6
FROM cohort_activity
GROUP BY 1
ORDER BY 1;