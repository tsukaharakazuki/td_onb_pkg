-- ======================================================================
-- LINE Conversion 送信用フォーマット
-- ======================================================================
SELECT
    event_id AS deduplication_key
    , 'conversion' AS event_type
    , 'web' AS source_type
    , CAST(event_time AS BIGINT) AS event_timestamp
    , em AS email
    , ph AS phone
    , client_user_agent AS user_agent
    , client_ip_address AS ip_address
    , event_source_url AS url
FROM
    capi_send
WHERE
    event_id IS NOT NULL
    AND event_id \!= ''
