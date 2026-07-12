SET search_path TO breathwork_app_schema;

-- Interaction-level detail
SELECT
    fe.user_id,
    fe.interaction_id,
    fe.session_id,
    fe.interaction_started_at AS started_at,
    fe.interaction_duration_seconds AS duration_seconds,
    dc.content_title,
    dc.difficulty,
    fe.interaction_completed AS completed,
    fe.completion_pct,
    fe.is_first_session,
    u.acquisition_channel,
    u.age,
    u.country,
    u.device_type
FROM fact_engagement fe
JOIN dim_user u ON u.user_id = fe.user_id
LEFT JOIN dim_content dc ON dc.content_id = fe.content_id
WHERE fe.interaction_id IS NOT NULL;

-- Engagement for churned users
SELECT
    DATE_TRUNC('week', fe.interaction_started_at) AS weeks,
    ROUND(COUNT(DISTINCT fe.session_id)::NUMERIC / NULLIF(COUNT(DISTINCT fe.user_id), 0), 2) AS avg_sessions_per_user,
    ROUND(AVG(fe.completion_pct), 2) AS avg_completion_pct,
    ROUND(AVG(fe.interaction_duration_seconds), 0) AS avg_session_time
FROM fact_engagement fe
JOIN fact_subscription fs ON fe.user_id = fs.user_id
WHERE fe.interaction_id IS NOT NULL
  AND fs.status = 'cancelled'
GROUP BY 1;

-- Retention cohort
WITH user_cohort AS (
    SELECT user_id, DATE_TRUNC('week', created_at) AS cohort_week
    FROM dim_user
),
user_activity AS (
    SELECT user_id, DATE_TRUNC('week', interaction_started_at) AS activity_week
    FROM fact_engagement
    WHERE interaction_id IS NOT NULL
),
cohort_activity AS (
    SELECT
        uc.user_id,
        uc.cohort_week,
        ua.activity_week,
        EXTRACT(DAY FROM (ua.activity_week - uc.cohort_week)) / 7 AS weeks_since_signup
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