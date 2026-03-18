-- ======================================================================
-- 共通: 送信ログ記録
-- ======================================================================
-- 送信対象データのオーダーIDをログテーブルに記録する。
-- 次回以降の送信で重複送信を防ぐ。
-- ======================================================================

SELECT
    event_name
    , event_time
    , em
    , ph
    , fn
    , ln
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
FROM
    capi_send_${b.brand_name}
