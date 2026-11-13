-- ======================================================================
-- OpenAI Ads Conversion API: 購買イベント(order_created)
-- ======================================================================
-- 時刻はUnixミリ秒。金額は通貨の最小単位（JPY=1、USD=100等）へ変換。
-- PIIはraw/64桁SHA-256のどちらもコネクタで正規化・ハッシュ処理する。
SELECT
    event_id
    , '${b.openai_event_type}' AS event_type
    , CAST(event_time AS BIGINT) * 1000 AS event_timestamp
    , CASE WHEN source_type = 'daily'
        THEN '${b.openai_daily_action_source}'
        ELSE '${b.openai_action_source}'
      END AS action_source
    , event_source_url AS source_url
    , CAST(ROUND(value_decimal * CAST(${b.openai_amount_multiplier} AS DECIMAL(7, 0))) AS BIGINT) AS data_amount
    , UPPER(currency) AS data_currency
    , NULLIF(TRIM(CAST(em AS VARCHAR)), '') AS email
    , NULLIF(TRIM(CAST(ph AS VARCHAR)), '') AS phone_number
    , NULLIF(TRIM(member_id), '') AS external_id
    , NULLIF(TRIM(country), '') AS country
    , client_ip_address AS ip_address
    , client_user_agent AS user_agent
    , obref
    , oppref
FROM
    capi_openai_send
