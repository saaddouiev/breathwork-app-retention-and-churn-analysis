CREATE TABLE IF NOT EXISTS stg_subscriptions AS
SELECT
    subscription_id,
    user_id,
    plan,
    TRIM(status) AS status,
    NULLIF(started_at, '')::TIMESTAMP AS started_at,
    cancelled_at::TIMESTAMP AS cancelled_at,
    COALESCE(NULLIF(cancellation_reason, ''), 'unknown') AS cancellation_reason,
    NULLIF(billing_amount, '')::DECIMAL AS billing_amount,
    billing_currency,
    reactivated::BOOLEAN AS reactivated
FROM breathwork_app_schema.raw_subscriptions;

SET search_path TO breathwork_app_schema;
ALTER TABLE stg_subscriptions ADD CONSTRAINT pk_stg_subscriptions PRIMARY KEY (subscription_id);
