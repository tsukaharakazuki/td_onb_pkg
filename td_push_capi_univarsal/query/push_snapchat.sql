-- ======================================================================
-- Snapchat CAPI 送信用フォーマット
-- ======================================================================
SELECT
    'PURCHASE' AS event_name
    , event_time
    , 'WEB' AS action_source
    , em AS email
    , ph AS phone_number
    , client_user_agent AS user_agent
    , client_ip_address AS ip_address
    , CAST(value AS DOUBLE) AS price
    , currency
    , event_id AS transaction_id
FROM
    capi_send
WHERE
    em IS NOT NULL
    AND em \!= ''
