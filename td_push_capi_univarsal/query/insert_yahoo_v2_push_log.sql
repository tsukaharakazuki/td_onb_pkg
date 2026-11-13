-- ======================================================================
-- Yahoo / LINE v2: 実際の送信対象だけをログ記録（test_flag=trueでは呼ばない）
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
FROM
    capi_yahoo_v2_send
