-- ======================================================================
-- Facebook CAPI 送信用フォーマット
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
    capi_send
WHERE
    em IS NOT NULL
    AND em \!= ''
