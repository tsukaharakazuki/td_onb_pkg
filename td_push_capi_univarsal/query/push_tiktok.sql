-- ======================================================================
-- TikTok Events API 送信用フォーマット
-- ======================================================================
-- TikTok Events API (Web) の標準パラメータに準拠
-- 必須: event, timestamp, event_id
-- 識別子: email / phone_number / ip + user_agent のうち最低1つ
-- TDコネクタがハッシュ・正規化を自動処理
-- ======================================================================

SELECT
    'CompletePayment' AS event
    , CAST(event_time AS BIGINT) AS timestamp
    , event_id
    , em AS email
    , ph AS phone_number
    , CAST(value AS DOUBLE) AS value
    , currency
    , event_source_url AS url
    , client_user_agent AS user_agent
    , client_ip_address AS ip
FROM
    capi_send_${b.brand_name}
WHERE
    em IS NOT NULL
    AND em != ''
