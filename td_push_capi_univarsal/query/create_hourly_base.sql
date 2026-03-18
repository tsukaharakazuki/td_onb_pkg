-- ======================================================================
-- 毎時送信: JS-SDKデータからベースデータ作成（メアドあり）
-- ======================================================================
-- configで "" のカラムは NULLIF で NULL に変換される。
-- 各CAPIが必要とする最低限のカラムのみ共通ベースとして抽出。
-- プラットフォーム固有のフォーマットは push_*.sql 側で行う。
-- ======================================================================

WITH raw_data AS (
    SELECT
        ${b.col_order_id} AS event_id
        , ${b.col_email} AS em
        , NULLIF('${b.col_phone}', '') AS _has_phone
        , CASE WHEN '${b.col_phone}' != '' THEN ${b.col_phone} ELSE NULL END AS ph
        , CASE WHEN '${b.col_country}' != '' THEN ${b.col_country} ELSE NULL END AS country
        , ${b.col_amount} AS raw_amount
        , CASE WHEN '${b.col_member_id}' != '' THEN ${b.col_member_id} ELSE NULL END AS member_id
        , CASE WHEN '${b.col_user_agent}' != '' THEN ${b.col_user_agent} ELSE NULL END AS client_user_agent
        , CASE WHEN '${b.col_ip}' != '' THEN ${b.col_ip} ELSE NULL END AS client_ip_address
        , CASE WHEN '${b.col_url}' != '' THEN ${b.col_url} ELSE NULL END AS event_source_url
        , CASE WHEN '${b.col_fbc}' != '' THEN ${b.col_fbc} ELSE NULL END AS fbc
        , CASE WHEN '${b.col_fbp}' != '' THEN ${b.col_fbp} ELSE NULL END AS fbp
        , time
    FROM
        ${b.log_db}.${b.log_tbl}
    WHERE
        TD_TIME_RANGE(
            time
            , TD_TIME_ADD(TD_DATE_TRUNC('hour', TD_SCHEDULED_TIME(), 'JST'), '-2h', 'JST')
            , TD_TIME_ADD(TD_DATE_TRUNC('hour', TD_SCHEDULED_TIME(), 'JST'), '-1h', 'JST')
            , 'JST'
        )
        AND ${b.cnv_conditions}
)

, deduped AS (
    SELECT
        *
        , ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY time DESC) AS rn
    FROM
        raw_data
    WHERE
        event_id IS NOT NULL
        AND CAST(event_id AS VARCHAR) != ''
)

, aggregated AS (
    SELECT
        event_id
        , em
        , ph
        , country
        , SUM(CAST(raw_amount AS BIGINT)) AS value
        , member_id
        , client_user_agent
        , client_ip_address
        , event_source_url
        , fbc
        , fbp
        , time AS event_time
    FROM
        deduped
    WHERE
        rn = 1
        AND raw_amount IS NOT NULL
    GROUP BY
        event_id, em, ph, country, member_id
        , client_user_agent, client_ip_address, event_source_url
        , fbc, fbp, time
)

SELECT
    'Purchase' AS event_name
    , event_time
    , CAST(event_id AS VARCHAR) AS event_id
    , em
    , ph
    , country
    , value
    , '${common.currency}' AS currency
    , event_source_url
    , 'website' AS action_source
    , client_user_agent
    , client_ip_address
    , fbc
    , fbp
    , CAST(member_id AS VARCHAR) AS member_id
    , '${b.brand_name}' AS brand_name
    , 'hourly' AS source_type
FROM
    aggregated
