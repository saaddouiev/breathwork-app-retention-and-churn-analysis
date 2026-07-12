SET search_path TO breathwork_app_schema;

DROP TABLE IF EXISTS _activation_base;
CREATE TEMP TABLE _activation_base AS
SELECT
    u.user_id,
    u.acquisition_channel,
    u.country,
    u.device_type,
    u.trial_start_date,
    u.trial_end_date,
    u.converted_to_paid,
    u.converted_at,
    u.created_at,
    EXTRACT(DAY FROM MIN(fe.session_started_at) - u.created_at) AS days_to_first_session,
    EXTRACT(DAY FROM u.converted_at - u.created_at) AS days_to_convert,
    MAX(CASE WHEN fe.is_first_session = TRUE AND fe.interaction_completed = TRUE THEN 1 ELSE 0 END) AS completed_content_in_first_session,
    COUNT(DISTINCT CASE
        WHEN fe.session_started_at BETWEEN u.trial_start_date AND u.trial_end_date
        THEN fe.session_id END) AS sessions_in_trial
FROM dim_user u
LEFT JOIN fact_engagement fe ON fe.user_id = u.user_id
GROUP BY
    u.user_id, u.acquisition_channel, u.country, u.device_type,
    u.trial_start_date, u.trial_end_date, u.converted_to_paid,
    u.converted_at, u.created_at;

-- Conversion Rate
SELECT
    ROUND(100.0 * SUM(converted_to_paid::INT) / COUNT(user_id), 2) AS conversion_rate
FROM _activation_base;

-- Conversion Rate by Channel
SELECT
    acquisition_channel,
    ROUND(100.0 * SUM(converted_to_paid::INT) / COUNT(user_id), 2) AS conversion_rate
FROM _activation_base
GROUP BY acquisition_channel;

-- Session completion and Conversion Rate
SELECT
    acquisition_channel,
    completed_content_in_first_session,
    ROUND(100.0 * SUM(converted_to_paid::INT) / COUNT(user_id), 2) AS conversion_rate
FROM _activation_base
GROUP BY completed_content_in_first_session, acquisition_channel;

-- Days to first session by acquisition channel
SELECT
    acquisition_channel,
    ROUND(AVG(NULLIF(days_to_first_session, 0)), 2) AS avg_days_1st_session
FROM _activation_base
GROUP BY acquisition_channel;

-- Average sessions during free trial per acquisition channel
SELECT
    acquisition_channel,
    ROUND(AVG(NULLIF(sessions_in_trial, 0)), 2) AS avg_sessions_in_trial
FROM _activation_base
GROUP BY acquisition_channel;

-- Percentage of users who complete their first session by acquisition channel
SELECT
    acquisition_channel,
    ROUND(100.0 * SUM(completed_content_in_first_session::INT) / COUNT(user_id), 2) AS pct_completed_first_session
FROM _activation_base
GROUP BY acquisition_channel;

-- Completion pct by channel + content type, first-session interactions only
SELECT
    u.acquisition_channel,
    dc.content_type,
    ROUND(AVG(fe.completion_pct), 2) AS completion_pct_avg,
    COUNT(DISTINCT fe.user_id) AS users_interacted
FROM fact_engagement fe
JOIN dim_user u ON u.user_id = fe.user_id
JOIN dim_content dc ON dc.content_id = fe.content_id
WHERE fe.is_first_session = TRUE
GROUP BY u.acquisition_channel, dc.content_type
ORDER BY users_interacted DESC;

-- Conversion rate among users who completed content in their first session
SELECT
    acquisition_channel,
    ROUND(100.0 * SUM(converted_to_paid::INT) / COUNT(*), 2) AS conversion_rate
FROM _activation_base
WHERE completed_content_in_first_session = 1
GROUP BY acquisition_channel
ORDER BY conversion_rate DESC;