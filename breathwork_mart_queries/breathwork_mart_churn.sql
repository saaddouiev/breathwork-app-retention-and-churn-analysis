SET SEARCH_PATH TO breathwork_app_schema;

CREATE VIEW mart_churn AS
    SELECT
        s.user_id,
        s.subscription_id,
        s.started_at,
        s.cancelled_at,
        s.plan,
        SUM(p.amount) AS total_revenue,
        s.status,
        u.country,
        u.acquisition_channel,
        u.device_type,
        u.age,
        u.plan_type,
        s.reactivated,
        s.cancellation_reason
    FROM breathwork_app_schema.stg_subscriptions s
    LEFT JOIN breathwork_app_schema.stg_users u ON s.user_id = u.user_id
    LEFT JOIN breathwork_app_schema.stg_payments p ON s.subscription_id = p.subscription_id
    GROUP BY
        s.user_id,
        s.subscription_id,
        s.started_at,
        s.cancelled_at,
        s.plan,
        s.status,
        u.country,
        u.acquisition_channel,
        u.device_type,
        u.age,
        u.plan_type,
        s.reactivated,
        s.cancellation_reason;

SELECT * FROM mart_churn LIMIT 10;

-- Overall Churn Rate
SELECT
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS churned_customers,
    COUNT(DISTINCT subscription_id) AS starting_customers,
    ROUND(100.0 * COUNT(CASE WHEN status = 'cancelled' THEN 1 END) /
          NULLIF(COUNT(DISTINCT subscription_id), 0), 2) AS overall_churn_rate
FROM mart_churn;


-- Churn Rate by Plan

SELECT
    plan,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS churned_customers,
    COUNT(DISTINCT subscription_id) AS starting_customers,
    ROUND(100.0 * COUNT(CASE WHEN status = 'cancelled' THEN 1 END) /
          NULLIF(COUNT(DISTINCT subscription_id), 0), 2) AS overall_churn_rate
FROM mart_churn
GROUP BY plan;

-- Churn Rate by Acquisition Channel
SELECT
    acquisition_channel,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS churned_customers,
    COUNT(DISTINCT subscription_id) AS starting_customers,
    ROUND(100.0 * COUNT(CASE WHEN status = 'cancelled' THEN 1 END) /
          NULLIF(COUNT(DISTINCT subscription_id), 0), 2) AS overall_churn_rate
FROM mart_churn
GROUP BY acquisition_channel;

-- Churn reason
SELECT
    cancellation_reason,
    COUNT(*) AS count
FROM mart_churn
WHERE status = 'cancelled'
GROUP BY cancellation_reason
ORDER BY count DESC;