-- ======================================================================
-- 日次補完: 購買データからベースデータ作成（メアドなし→JOIN）
-- ======================================================================
-- 全PF共通のベーステーブルを1つ作成する。
-- 会員マスタからメアドをJOIN。
-- 購買データにはWeb情報がないためNULL。
-- ======================================================================

WITH purchase_data AS (
    SELECT
        ${common.pcol_order_id} AS event_id
        , ${common.pcol_amount} AS raw_amount
        , ${common.pcol_member_id ? 'CAST(' + common.pcol_member_id + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS member_id
        , ${common.pcol_phone ? 'CAST(' + common.pcol_phone + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS ph
        , ${common.pcol_url ? 'CAST(' + common.pcol_url + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS event_source_url
        , ${common.pcol_ly_su ? 'CAST(' + common.pcol_ly_su + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS ly_su
        , ${common.pcol_ly_c ? 'CAST(' + common.pcol_ly_c + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS ly_c
        , ${common.pcol_ly_r ? 'CAST(' + common.pcol_ly_r + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS ly_r
        , ${common.pcol_line_uid ? 'CAST(' + common.pcol_line_uid + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS line_uid
        , ${common.pcol_ifa ? 'CAST(' + common.pcol_ifa + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS ifa
        , ${common.pcol_referrer_url ? 'CAST(' + common.pcol_referrer_url + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS referrer_url
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
        AND CAST(event_id AS VARCHAR) != ''
)

, aggregated AS (
    SELECT
        event_id
        , SUM(CAST(CAST(raw_amount AS DOUBLE) AS BIGINT)) AS value
        , CAST(SUM(CAST(raw_amount AS DECIMAL(30, 6))) AS DECIMAL(30, 6)) AS value_decimal
        , member_id
        , ph
        , event_source_url
        , ly_su
        , ly_c
        , ly_r
        , line_uid
        , ifa
        , referrer_url
        , event_time
    FROM
        deduped
    WHERE
        rn = 1
        AND raw_amount IS NOT NULL
    GROUP BY
        event_id, member_id, ph, event_source_url, ly_su, ly_c, ly_r, line_uid, ifa, referrer_url, event_time
)

, with_email AS (
    SELECT
        a.*
        , ${common.member_db && common.member_tbl && common.member_id_col && common.member_email_col && common.pcol_member_id ? 'm.' + common.member_email_col : 'CAST(NULL AS VARCHAR)'} AS em
    FROM
        aggregated a
    -- 会員マスタ未設定時はJOINしない（Cookie / LINE UIDのみで送る場合）
    ${common.member_db && common.member_tbl && common.member_id_col && common.member_email_col && common.pcol_member_id ? 'LEFT JOIN ' + common.member_db + '.' + common.member_tbl + ' m ON CAST(a.member_id AS VARCHAR) = CAST(m.' + common.member_id_col + ' AS VARCHAR)' : ''}
)

SELECT
    'Purchase' AS event_name
    , event_time
    , CAST(event_id AS VARCHAR) AS event_id
    , em
    , ph
    , CAST(NULL AS VARCHAR) AS country
    , value
    , '${common.currency}' AS currency
    , event_source_url
    , 'website' AS action_source
    , CAST(NULL AS VARCHAR) AS client_user_agent
    , CAST(NULL AS VARCHAR) AS client_ip_address
    , CAST(NULL AS VARCHAR) AS fbc
    , CAST(NULL AS VARCHAR) AS fbp
    , CAST(member_id AS VARCHAR) AS member_id
    , 'daily' AS source_type
    , ly_su
    , ly_c
    , ly_r
    , line_uid
    , ifa
    , referrer_url
    , CAST(NULL AS VARCHAR) AS obref
    , CAST(NULL AS VARCHAR) AS oppref
    , value_decimal
FROM
    with_email
