-- ======================================================================
-- Google Data Manager for Conversions: 実際の送信対象のみログ記録
-- ======================================================================
-- push_google_data_manager_for_conversions.sql と同じ適格条件を使用し、
-- SQLで除外されたレコードを送信済みにしない。
-- ======================================================================
WITH eligible AS (
    SELECT
        *
        , NULLIF(url_extract_parameter(event_source_url, 'gclid'), '') AS google_gclid
        , NULLIF(url_extract_parameter(event_source_url, 'gbraid'), '') AS google_gbraid
        , NULLIF(url_extract_parameter(event_source_url, 'wbraid'), '') AS google_wbraid
        , NULLIF(url_extract_parameter(event_source_url, 'dclid'), '') AS google_dclid
        , NULLIF(TRIM(CAST(em AS VARCHAR)), '') AS google_email
        , NULLIF(TRIM(CAST(client_ip_address AS VARCHAR)), '') AS google_ip_address
    FROM
        capi_send
    WHERE
        event_time IS NOT NULL
)

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
    eligible
WHERE
    (
        '${b.google_dm_conversion_type}' = 'OFFLINE'
        AND (
            google_gclid IS NOT NULL
            OR google_gbraid IS NOT NULL
            OR google_wbraid IS NOT NULL
            OR google_dclid IS NOT NULL
            OR google_email IS NOT NULL
            OR google_ip_address IS NOT NULL
        )
    )
    OR (
        '${b.google_dm_conversion_type}' = 'ONLINE'
        AND NULLIF(TRIM(CAST(event_id AS VARCHAR)), '') IS NOT NULL
        AND (
            google_gclid IS NOT NULL
            OR google_gbraid IS NOT NULL
            OR google_wbraid IS NOT NULL
            OR google_dclid IS NOT NULL
            OR google_email IS NOT NULL
            OR google_ip_address IS NOT NULL
        )
    )
    OR (
        '${b.google_dm_conversion_type}' = 'STORE_SALES'
        AND NULLIF(TRIM(CAST(event_id AS VARCHAR)), '') IS NOT NULL
        AND value IS NOT NULL
        AND NULLIF('${b.google_dm_store_id}', '') IS NOT NULL
        AND google_email IS NOT NULL
    )
