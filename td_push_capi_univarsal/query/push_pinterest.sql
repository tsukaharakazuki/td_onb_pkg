-- ======================================================================
-- Pinterest CAPI 送信用フォーマット
-- ======================================================================
-- 必須: event_name, action_source, event_time, event_id
-- 識別子: em / hashed_maids / (client_ip_address + client_user_agent)
-- checkout時は currency, value 推奨
-- TDコネクタが自動でSHA-256ハッシュ処理
-- ======================================================================

SELECT
    'checkout' AS event_name
    , 'web' AS action_source
    , CAST(event_time AS BIGINT) AS event_time
    , event_id
    , em
    , ph
    , CAST(value AS DOUBLE) AS value
    , '${common.currency}' AS currency
    , event_source_url
    , client_user_agent
    , client_ip_address
    , event_id AS order_id
FROM
    capi_send_${b.brand_name}
WHERE
    em IS NOT NULL
    AND em != ''
