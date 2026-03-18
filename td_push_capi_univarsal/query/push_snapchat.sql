-- ======================================================================
-- Snapchat CAPI 送信用フォーマット
-- ======================================================================
-- 必須: event_name, event_time, action_source
-- 識別子: em / ph / client_ip_address+client_user_agent のうち最低1つ
-- PURCHASE時は currency, value も必須
-- TDコネクタが自動で正規化・ハッシュを処理
-- ======================================================================

SELECT
    'PURCHASE' AS event_name
    , CAST(event_time AS BIGINT) AS event_time
    , em
    , ph
    , country
    , event_source_url
    , client_user_agent
    , client_ip_address
    , currency
    , CAST(value AS DOUBLE) AS value
    , event_id AS order_id
FROM
    capi_send_${b.brand_name}
WHERE
    em IS NOT NULL
    AND em != ''
