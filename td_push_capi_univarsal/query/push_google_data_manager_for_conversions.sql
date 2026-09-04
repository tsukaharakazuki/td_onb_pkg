-- ======================================================================
-- Google Data Manager for Conversions 送信用フォーマット
-- ======================================================================
-- conversion_type: OFFLINE / ONLINE / STORE_SALES
-- event_time は TD の Unix秒から Google Data Manager の epoch ms に変換する。
-- 現行の共通ベースではURL内のGoogle Click ID / email / ip_addressを識別子に使用する。
-- STORE_SALES は日次WFのみで送信し、email を必須とする。
-- ======================================================================
WITH normalized AS (
    SELECT
        CAST(event_time AS BIGINT) * 1000 AS event_timestamp
        , NULLIF('${b.google_dm_event_source}', '') AS event_source
        , NULLIF(TRIM(CAST(event_id AS VARCHAR)), '') AS transaction_id
        , CAST(value AS DOUBLE) AS conversion_value
        , UPPER(CAST(currency AS VARCHAR)) AS currency
        , event_name
        , NULLIF(TRIM(CAST(member_id AS VARCHAR)), '') AS user_id
        , NULLIF(url_extract_parameter(event_source_url, 'gclid'), '') AS gclid
        , NULLIF(url_extract_parameter(event_source_url, 'gbraid'), '') AS gbraid
        , NULLIF(url_extract_parameter(event_source_url, 'wbraid'), '') AS wbraid
        , NULLIF(url_extract_parameter(event_source_url, 'dclid'), '') AS dclid
        , NULLIF(TRIM(CAST(em AS VARCHAR)), '') AS email
        , NULLIF(TRIM(CAST(client_ip_address AS VARCHAR)), '') AS ip_address
        , NULLIF(TRIM(CAST(client_user_agent AS VARCHAR)), '') AS device_user_agent
        , NULLIF('${b.google_dm_store_id}', '') AS store_id
    FROM
        capi_send
    WHERE
        event_time IS NOT NULL
)

SELECT
    event_timestamp
    , event_source
    , transaction_id
    , conversion_value
    , currency
    , event_name
    , user_id
    , gclid
    , gbraid
    , wbraid
    , dclid
    , email
    , ip_address
    , device_user_agent
    , store_id
FROM
    normalized
WHERE
    (
        '${b.google_dm_conversion_type}' = 'OFFLINE'
        AND (
            gclid IS NOT NULL
            OR gbraid IS NOT NULL
            OR wbraid IS NOT NULL
            OR dclid IS NOT NULL
            OR email IS NOT NULL
            OR ip_address IS NOT NULL
        )
    )
    OR (
        '${b.google_dm_conversion_type}' = 'ONLINE'
        AND transaction_id IS NOT NULL
        AND (
            gclid IS NOT NULL
            OR gbraid IS NOT NULL
            OR wbraid IS NOT NULL
            OR dclid IS NOT NULL
            OR email IS NOT NULL
            OR ip_address IS NOT NULL
        )
    )
    OR (
        '${b.google_dm_conversion_type}' = 'STORE_SALES'
        AND transaction_id IS NOT NULL
        AND conversion_value IS NOT NULL
        AND store_id IS NOT NULL
        AND email IS NOT NULL
    )
