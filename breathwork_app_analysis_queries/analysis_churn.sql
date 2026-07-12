SET search_path TO breathwork_app_schema;

-- Subscription-level detail
SELECT
    fs.user_id, fs.subscription_id, fs.started_date_key AS started_at,
    fs.cancelled_date_key AS cancelled_at, fs.plan, fs.total_revenue,
    fs.status, u.country, u.acquisition_channel, u.device_type, u.age,
    fs.reactivated, fs.cancellation_reason
FROM fact_subscription fs
JOIN dim_user u ON u.user_id = fs.user_id
LIMIT 10;

-- Overall churn rate
SELECT
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS churned_customers,
    COUNT(DISTINCT subscription_id) AS starting_customers,
    ROUND(100.0 * COUNT(CASE WHEN status = 'cancelled' THEN 1 END) /
          NULLIF(COUNT(DISTINCT subscription_id), 0), 2) AS overall_churn_rate
FROM fact_subscription;

-- Churn rate by plan
SELECT
    plan,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS churned_customers,
    COUNT(DISTINCT subscription_id) AS starting_customers,
    ROUND(100.0 * COUNT(CASE WHEN status = 'cancelled' THEN 1 END) /
          NULLIF(COUNT(DISTINCT subscription_id), 0), 2) AS overall_churn_rate
FROM fact_subscription
GROUP BY plan;

-- Churn rate by acquisition channel
SELECT
    u.acquisition_channel,
    COUNT(CASE WHEN fs.status = 'cancelled' THEN 1 END) AS churned_customers,
    COUNT(DISTINCT fs.subscription_id) AS starting_customers,
    ROUND(100.0 * COUNT(CASE WHEN fs.status = 'cancelled' THEN 1 END) /
          NULLIF(COUNT(DISTINCT fs.subscription_id), 0), 2) AS overall_churn_rate
FROM fact_subscription fs
JOIN dim_user u ON u.user_id = fs.user_id
GROUP BY u.acquisition_channel;

-- Churn reason
SELECT
    cancellation_reason,
    COUNT(*) AS count
FROM fact_subscription
WHERE status = 'cancelled'
GROUP BY cancellation_reason
ORDER BY count DESC;

-- Churn rate using only each user's most recent subscription (sanity check
-- against the subscription-grain rate above)
WITH latest_sub_date AS (
    SELECT user_id, MAX(started_date_key) AS latest_started_date_key
    FROM fact_subscription
    GROUP BY user_id
),
latest_sub AS (
    SELECT fs.user_id, fs.status
    FROM fact_subscription fs
    JOIN latest_sub_date lsd
        ON fs.user_id = lsd.user_id
        AND fs.started_date_key = lsd.latest_started_date_key
)
SELECT
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS churned_users,
    COUNT(*) AS total_users,
    ROUND(100.0 * COUNT(CASE WHEN status = 'cancelled' THEN 1 END) / COUNT(*), 2) AS churn_rate_pct
FROM latest_sub;

-- Revenue lost by cancellation reason
SELECT
    cancellation_reason,
    COUNT(*) AS churned_users,
    ROUND(AVG(total_revenue), 2) AS avg_revenue_per_churned_user,
    ROUND(SUM(total_revenue), 2) AS total_revenue_lost
FROM fact_subscription
WHERE status = 'cancelled'
GROUP BY cancellation_reason
ORDER BY total_revenue_lost DESC;

-- Churn rate and revenue by acquisition channel
SELECT
    u.acquisition_channel,
    COUNT(DISTINCT fs.subscription_id) AS total_customers,
    COUNT(CASE WHEN fs.status = 'cancelled' THEN 1 END) AS churned_customers,
    ROUND(100.0 * COUNT(CASE WHEN fs.status = 'cancelled' THEN 1 END) /
          NULLIF(COUNT(DISTINCT fs.subscription_id), 0), 2) AS churn_rate,
    ROUND(AVG(fs.total_revenue), 2) AS avg_revenue_per_customer,
    ROUND(SUM(fs.total_revenue), 2) AS total_revenue
FROM fact_subscription fs
JOIN dim_user u ON u.user_id = fs.user_id
GROUP BY u.acquisition_channel
ORDER BY avg_revenue_per_customer DESC;


SELECT date_key, COUNT(DISTINCT user_id) AS dau
FROM breathwork_app_schema.fact_engagement
GROUP BY date_key;