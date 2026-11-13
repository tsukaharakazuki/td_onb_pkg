-- ======================================================================
-- Yahoo! Ads Conversion API V2 送信用フォーマット（LINE も同じ形式）
-- ======================================================================
-- 接続・タグ・チャネルはブランド別に設定する。
-- ly_* と電話番号の整形は prepare_yahoo_v2.sql で行っている。
SELECT
    '${b.event_type}' AS event_type
    , NULLIF('${b.event_snippet_id}', '') AS event_snippet_id
    , CAST(event_time AS BIGINT) AS event_time
    , ${b.test_flag} AS test_flag
    , event_id AS transaction_id
    , NULLIF(TRIM(CAST(em AS VARCHAR)), '') AS hashed_email
    , NULLIF(TRIM(phone_valid), '') AS hashed_phone_number
    , ly_su_valid AS ly_su
    , ly_c_valid AS ly_c
    , ly_r_valid AS ly_r
    , NULLIF(TRIM(ifa), '') AS ifa
    , CASE WHEN '${b.channel_id}' != '' THEN NULLIF(TRIM(line_uid), '') END AS line_uid
    , event_source_url AS url
    , referrer_url
    , client_user_agent AS user_agent
    , client_ip_address AS ip
    , CAST(value_decimal AS DOUBLE) AS custom_value
    , NULLIF('${b.custom_label}', '') AS custom_label
    , UPPER(currency) AS custom_currency
FROM
    capi_yahoo_v2_send
