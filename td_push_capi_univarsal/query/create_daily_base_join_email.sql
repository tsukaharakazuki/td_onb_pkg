-- ======================================================================
-- 日次補完: 購買データからベースデータ作成（メアドなし→会員IDでJOIN）
-- ======================================================================

WITH purchase_data AS (
    SELECT
        ${b.pcol_order_id} AS event_id
        , ${b.pcol_amount} AS raw_amount
        , ${b.pcol_member_id} AS member_id
        , ${b.pcol_time} AS event_time
    FROM
        ${b.purchase_db}.${b.purchase_tbl}
    WHERE
        TD_INTERVAL(${b.pcol_time}, '-1d', 'JST')
        AND ${b.purchase_conditions}
)

, deduped AS (
    SELECT
        *
        , ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY event_time DESC) AS rn
    FROM
        purchase_data
    WHERE
        event_id IS NOT NULL
        AND CAST(event_id AS VARCHAR) != ''
)

, aggregated AS (
    SELECT
        event_id
        , SUM(CAST(raw_amount AS BIGINT)) AS value
        , member_id
        , event_time
    FROM
        deduped
    WHERE
        rn = 1
        AND raw_amount IS NOT NULL
    GROUP BY
        event_id, member_id, event_time
)

, with_email AS (
    SELECT
        a.*
        , m.${b.member_email_col} AS em
    FROM
        aggregated a
    LEFT JOIN
        ${b.member_db}.${b.member_tbl} m
        ON CAST(a.member_id AS VARCHAR) = CAST(m.${b.member_id_col} AS VARCHAR)
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
    , '${b.brand_name}' AS brand_name
    , 'daily' AS source_type
FROM
    with_email
