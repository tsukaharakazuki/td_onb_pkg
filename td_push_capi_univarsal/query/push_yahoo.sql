-- ======================================================================
-- Yahoo Ads Conversion 送信用フォーマット
-- ======================================================================
-- 必須: event_time(Long), yahoo_ydn_conv_io, yahoo_ydn_conv_label
-- 識別子: hashed_email / hashed_phone_number / yclid のうち最低1つ
-- TDコネクタが自動でSHA-256ハッシュを行う
-- ======================================================================

SELECT
    em AS hashed_email
    , ph AS hashed_phone_number
    , event_time
    , '${b.yahoo_ydn_conv_io}' AS yahoo_ydn_conv_io
    , '${b.yahoo_ydn_conv_label}' AS yahoo_ydn_conv_label
    , event_id AS yahoo_ydn_conv_transaction_id
    , CAST(value AS BIGINT) AS yahoo_ydn_conv_value
FROM
    capi_send_${b.brand_name}
WHERE
    em IS NOT NULL
    AND em != ''
