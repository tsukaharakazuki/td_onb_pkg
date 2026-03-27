-- ======================================================================
-- Pinterest CAPI 送信用フォーマット
-- ======================================================================
SELECT
    'checkout' AS event_name
    , 'website' AS action_source
    , event_time
    , event_id
    , em AS email
    , ph AS phone_number
    , client_user_agent AS user_agent
    , client_ip_address AS ip_address
    , CAST(value AS DOUBLE) AS value
    , currency
    , event_id AS order_id
FROM
    capi_send
WHERE
    em IS NOT NULL
    AND em \!= ''
