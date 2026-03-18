-- ======================================================================
-- Google Enhanced Conversions - Store Sales 送信用フォーマット
-- ======================================================================
-- 必須: email or phone_number (最低1つ), tran_datetime, tran_amount,
--       tran_currency, conversion_action_id
-- TDコネクタが自動でハッシュ処理
-- ======================================================================

SELECT
    em AS email
    , ph AS phone_number
    , TD_TIME_FORMAT(event_time, 'yyyy-MM-dd HH:mm:ss+09:00') AS tran_datetime
    , CAST(value AS DOUBLE) AS tran_amount
    , '${common.currency}' AS tran_currency
    , '${b.google_conversion_action_id}' AS conversion_action_id
    , event_id AS order_id
FROM
    capi_send_${b.brand_name}
WHERE
    em IS NOT NULL
    AND em != ''
