-- ======================================================================
-- Google Enhanced Conversions - Web 送信用フォーマット
-- ======================================================================
-- 必須: email or address (最低1つ), order_id, conversion_action_id,
--       adjustment_date_time
-- TDコネクタが自動でハッシュ処理
-- ======================================================================

SELECT
    em AS email
    , ph AS phone_number
    , event_id AS order_id
    , '${b.google_conversion_action_id}' AS conversion_action_id
    , TD_TIME_FORMAT(event_time, 'yyyy-MM-dd HH:mm:ss+09:00') AS adjustment_date_time
    , CAST(value AS DOUBLE) AS conversion_value
    , '${common.currency}' AS currency_code
    , client_user_agent AS user_agent
FROM
    capi_send_${b.brand_name}
WHERE
    em IS NOT NULL
    AND em != ''
