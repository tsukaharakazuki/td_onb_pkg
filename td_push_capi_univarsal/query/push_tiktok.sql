-- ======================================================================
-- TikTok Events API 送信用フォーマット
-- ======================================================================
-- 注意: event_time カラム名を変えるとコネクタエラーになる
-- ======================================================================
SELECT
    'CompletePayment' AS event
    , CAST(event_time AS BIGINT) AS event_time
    , event_id
    , em AS email
    , ph AS phone_number
    , CAST(value AS DOUBLE) AS value
    , currency
    , event_source_url AS url
    , client_user_agent AS user_agent
    , client_ip_address AS ip
FROM
    capi_send
WHERE
    em IS NOT NULL
    AND em \!= ''
