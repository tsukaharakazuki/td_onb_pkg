-- ======================================================================
-- 共通: 従来媒体（メアドで送信するもの）の送信ログ記録
-- ======================================================================
-- push_facebook / push_tiktok / push_google_store_sales / push_google_enhanced_web /
-- push_pinterest / push_snapchat / push_x.sql と同じ適格条件を使い、
-- 送信しなかった行を送信済みにしない。
-- ======================================================================
SELECT
    event_name
    , event_time
    , em
    , ph
    , CAST(NULL AS VARCHAR) AS fn
    , CAST(NULL AS VARCHAR) AS ln
    , country
    , value
    , currency
    , event_source_url
    , action_source
    , client_user_agent
    , client_ip_address
    , event_id
    , TD_SCHEDULED_TIME() AS push_time
    , '${b.brand_name}' AS brand_name
    , source_type
    , '${b.platform}' AS platform
FROM
    capi_send
WHERE
    em IS NOT NULL
    AND em != ''
