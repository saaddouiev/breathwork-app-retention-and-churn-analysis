SET SEARCH_PATH TO breathwork_app_schema;
DROP VIEW IF EXISTS mart_user_activation;

CREATE VIEW mart_user_activation AS
SELECT
    u.user_id,
    u.acquisition_channel,
    u.country,
    u.device_type,
    u.plan_type,
    u.trial_start_date,
    u.trial_end_date,
    u.converted_to_paid,
    u.converted_at,
    u.created_at,
    EXTRACT(DAY FROM MIN(s.started_at) - u.created_at) AS days_to_first_session,
    EXTRACT(DAY FROM u.converted_at - u.created_at) AS days_to_convert,
    MAX(CASE WHEN ci.is_first_session = TRUE AND ci.completed = TRUE THEN 1 ELSE 0 END) AS completed_content_in_first_session,
    (SELECT COUNT(*) FROM breathwork_app_schema.stg_sessions s WHERE s.user_id = u.user_id
     AND s.started_at BETWEEN u.trial_start_date AND u.trial_end_date) AS sessions_in_trial
FROM breathwork_app_schema.stg_users u
LEFT JOIN breathwork_app_schema.stg_sessions s ON u.user_id = s.user_id
LEFT JOIN breathwork_app_schema.stg_content_interactions ci ON u.user_id = ci.user_id
GROUP BY
    u.user_id,
    u.acquisition_channel,
    u.country,
    u.device_type,
    u.plan_type,
    u.trial_start_date,
    u.trial_end_date,
    u.converted_to_paid,
    u.converted_at,
    u.created_at;

-- Conversion Rate
SELECT
    ROUND(100.0 * SUM(converted_to_paid::INT) / COUNT(user_id), 2) as conversion_rate
FROM mart_user_activation;

-- Conversion Rate by Channel
SELECT
    acquisition_channel,
    ROUND(100.0 * SUM(converted_to_paid::INT) / COUNT(user_id), 2) as conversion_rate
FROM mart_user_activation
GROUP BY acquisition_channel;

-- Session completion and Conversion Rate
SELECT
    acquisition_channel,
    completed_content_in_first_session,
    ROUND(100.0 * SUM(converted_to_paid::INT) /  COUNT(user_id), 2) as conversion_rate
FROM mart_user_activation
GROUP BY completed_content_in_first_session, acquisition_channel

-- Days to first session by acquistion channel
SELECT
    acquisition_channel,
    ROUND(AVG(NULLIF(days_to_first_session, 0)), 2) AS avg_days_1st_session
FROM mart_user_activation
GROUP BY acquisition_channel;

-- Average sessions during free trial per Acquisition channel
SELECT
    ua.acquisition_channel,
    ROUND(AVG(NULLIF(ua.sessions_in_trial, 0)), 2) AS avg_sessions_in_trial
FROM mart_user_activation ua
GROUP BY 1;

-- Percentage of users who complete their first session by acquisition channel
SELECT
    acquisition_channel,
    ROUND(100.0 * SUM(completed_content_in_first_session::INT) / COUNT(user_id), 2)
FROM mart_user_activation
GROUP BY acquisition_channel;


SELECT
    acquisition_channel,
    content_type,
    ROUND(AVG(completion_pct), 2) AS completion_pct_avg,
    COUNT(DISTINCT a.user_id) AS users_interacted
FROM mart_user_activation a
JOIN stg_content_interactions c
    ON a.user_id = c.user_id
WHERE is_first_session = TRUE
GROUP BY 1, 2
ORDER BY users_interacted DESC;


SELECT
    acquisition_channel,
    ROUND(100.0 * SUM(converted_to_paid::INT) / COUNT(*), 2) AS conversion_rate
FROM mart_user_activation
WHERE completed_content_in_first_session = 1
GROUP BY acquisition_channel
ORDER BY conversion_rate DESC;