CREATE TABLE stg_payments AS
SELECT
    payment_id,
    user_id,
    subscription_id,
    amount::NUMERIC(10,2) AS amount,
    UPPER(currency) AS currency,
    LOWER(TRIM(status)) AS status,
    paid_at::TIMESTAMP AS paid_at,
    NULLIF(TRIM(failure_reason), '') AS failure_reason
FROM breathwork_app_schema.raw_payments;

SET search_path TO breathwork_app_schema;
ALTER TABLE stg_payments ADD CONSTRAINT pk_stg_payments PRIMARY KEY (payment_id);
