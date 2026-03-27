-- ======================================================================
-- Yahoo 広告 コンバージョン送信用フォーマット
-- ======================================================================
SELECT
    event_time
    , '${b.yahoo_ydn_conv_io}' AS yahoo_ydn_conv_io
    , '${b.yahoo_ydn_conv_label}' AS yahoo_ydn_conv_label
    , em AS hashed_email
    , event_id AS transaction_id
    , CAST(value AS DOUBLE) AS conv_value
    , currency AS conv_value_currency
FROM
    capi_send
WHERE
    em IS NOT NULL
    AND em \!= ''
