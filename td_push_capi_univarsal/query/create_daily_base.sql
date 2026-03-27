-- ======================================================================
-- 日次補完: 購買データからベースデータ作成（メアドあり）
-- ======================================================================
-- 全PF共通のベーステーブルを1つ作成する。
-- 購買データにはWeb情報がないためNULL。
-- ======================================================================

WITH purchase_data AS (
    SELECT
        ${common.pcol_order_id} AS event_id
        , ${common.pcol_email} AS em
        , ${common.pcol_amount} AS raw_amount
        , ${common.pcol_member_id} AS member_id
        , ${common.pcol_time} AS event_time
    FROM
        ${common.purchase_db}.${common.purchase_tbl}
    WHERE
        TD_INTERVAL(${common.pcol_time}, '-1d', 'JST')
        AND ${common.purchase_conditions}
)

, deduped AS (
    SELECT
        *
        , ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY event_time DESC) AS rn
    FROM
        purchase_data
    WHERE
        event_id IS NOT NULL
        AND CAST(event_id AS VARCHAR) \!= ''
)

, aggregated AS (
    SELECT
        event_id
        , em
        , SUM(CAST(CAST(raw_amount AS DOUBLE) AS BIGINT)) AS value
        , member_id
        , event_time
    FROM
        deduped
    WHERE
        rn = 1
        AND raw_amount IS NOT NULL
    GROUP BY
        event_id, em, member_id, event_time
)

SELECT
    'Purchase' AS event_name
    , event_time
    , CAST(event_id AS VARCHAR) AS event_id
    , em
    , CAST(NULL AS VARCHAR) AS ph
    , CAST(NULL AS VARCHAR) AS country
    , value
    , '${common.currency}' AS currency
    , CAST(NULL AS VARCHAR) AS event_source_url
    , 'website' AS action_source
    , CAST(NULL AS VARCHAR) AS client_user_agent
    , CAST(NULL AS VARCHAR) AS client_ip_address
    , CAST(NULL AS VARCHAR) AS fbc
    , CAST(NULL AS VARCHAR) AS fbp
    , CAST(member_id AS VARCHAR) AS member_id
    , 'daily' AS source_type
FROM
    aggregated
