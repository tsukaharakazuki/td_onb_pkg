-- ======================================================================
-- Facebook CAPI 送信用フォーマット
-- ======================================================================
-- 必須: event_name(String), event_time(Long)
-- 顧客情報: em/ph/country等のうち最低1つ
-- client_ip_address + client_user_agent はペアで必要
-- fbc/fbp はオプション（あれば送信精度向上）
-- TDコネクタが自動でハッシュ・正規化を行う
-- ======================================================================

SELECT
    event_name
    , event_time
    , em
    , ph
    , country AS ct
    , json_format(
        CAST(
            MAP(
                ARRAY['currency', 'value']
                , ARRAY[currency, CAST(value AS VARCHAR)]
            ) AS JSON
        )
    ) AS custom_data
    , currency
    , CAST(value AS DOUBLE) AS value
    , event_source_url
    , action_source
    , client_user_agent
    , client_ip_address
    , fbc
    , fbp
    , event_id
FROM
    capi_send_${b.brand_name}
WHERE
    em IS NOT NULL
    AND em != ''
