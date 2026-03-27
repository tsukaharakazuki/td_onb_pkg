-- ======================================================================
-- 毎時送信: JS-SDKデータからベースデータ作成（メアドなし→JOIN）
-- ======================================================================
-- 全PF共通のベーステーブルを1つ作成する。
-- JS-SDK側のメアドと会員マスタのメアドをCOALESCEで補完。
-- 全PFで必要なカラムを網羅（ないものはNULL）。
-- ======================================================================

WITH raw_data AS (
    SELECT
        ${common.col_order_id} AS event_id
        , ${common.col_email} AS js_email
        , CAST(NULL AS VARCHAR) AS ph
        , CAST(NULL AS VARCHAR) AS country
        , ${common.col_amount} AS raw_amount
        , ${common.col_member_id} AS member_id
        , ${common.col_user_agent} AS client_user_agent
        , ${common.col_ip} AS client_ip_address
        , ${common.col_url} AS event_source_url
        , CAST(NULL AS VARCHAR) AS fbc
        , CAST(NULL AS VARCHAR) AS fbp
        , time
    FROM
        ${common.log_db}.${common.log_tbl}
    WHERE
        TD_TIME_RANGE(
            time
            , TD_TIME_ADD(TD_DATE_TRUNC('hour', TD_SCHEDULED_TIME(), 'JST'), '-2h', 'JST')
            , TD_TIME_ADD(TD_DATE_TRUNC('hour', TD_SCHEDULED_TIME(), 'JST'), '-1h', 'JST')
            , 'JST'
        )
        AND ${common.cnv_conditions}
)

, deduped AS (
    SELECT
        *
        , ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY time DESC) AS rn
    FROM
        raw_data
    WHERE
        event_id IS NOT NULL
        AND CAST(event_id AS VARCHAR) \!= ''
)

, aggregated AS (
    SELECT
        event_id
        , js_email
        , ph
        , country
        , MAX(CAST(CAST(raw_amount AS DOUBLE) AS BIGINT)) AS value
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
        event_id, js_email, ph, country, member_id
        , client_user_agent, client_ip_address, event_source_url
        , fbc, fbp, time
)

, with_email AS (
    SELECT
        a.*
        , COALESCE(a.js_email, m.${common.member_email_col}) AS em
    FROM
        aggregated a
    LEFT JOIN
        ${common.member_db}.${common.member_tbl} m
        ON CAST(a.member_id AS VARCHAR) = CAST(m.${common.member_id_col} AS VARCHAR)
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
    , 'hourly' AS source_type
FROM
    with_email
