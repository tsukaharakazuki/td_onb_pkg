-- ======================================================================
-- 毎時送信: JS-SDKデータからベースデータ作成（メアドなし→JOIN）
-- ======================================================================
-- 全PF共通のベーステーブルを1つ作成する。
-- 会員マスタからメアドを補完。
-- 全PFで必要なカラムを網羅（ないものはNULL）。
-- ======================================================================

WITH raw_data AS (
    SELECT
        ${common.col_order_id} AS event_id
        , ${common.col_phone ? 'CAST(' + common.col_phone + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS ph
        , ${common.col_country ? 'CAST(' + common.col_country + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS country
        , ${common.col_amount} AS raw_amount
        , ${common.col_member_id ? 'CAST(' + common.col_member_id + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS member_id
        , ${common.col_user_agent ? 'CAST(' + common.col_user_agent + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS client_user_agent
        , ${common.col_ip ? 'CAST(' + common.col_ip + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS client_ip_address
        , ${common.col_url ? 'CAST(' + common.col_url + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS event_source_url
        , CAST(NULL AS VARCHAR) AS fbc
        , CAST(NULL AS VARCHAR) AS fbp
        , ${common.col_ly_su ? 'CAST(' + common.col_ly_su + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS ly_su
        , ${common.col_ly_c ? 'CAST(' + common.col_ly_c + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS ly_c
        , ${common.col_ly_r ? 'CAST(' + common.col_ly_r + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS ly_r
        , ${common.col_line_uid ? 'CAST(' + common.col_line_uid + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS line_uid
        , ${common.col_ifa ? 'CAST(' + common.col_ifa + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS ifa
        , ${common.col_referrer_url ? 'CAST(' + common.col_referrer_url + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS referrer_url
        , ${common.col_obref ? 'CAST(' + common.col_obref + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS obref
        , ${common.col_oppref ? 'CAST(' + common.col_oppref + ' AS VARCHAR)' : 'CAST(NULL AS VARCHAR)'} AS oppref
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
        AND CAST(event_id AS VARCHAR) != ''
)

, aggregated AS (
    SELECT
        event_id
        , ph
        , country
        , MAX(CAST(CAST(raw_amount AS DOUBLE) AS BIGINT)) AS value
        , MAX(CAST(raw_amount AS DECIMAL(30, 6))) AS value_decimal
        , member_id
        , client_user_agent
        , client_ip_address
        , event_source_url
        , fbc
        , fbp
        , ly_su
        , ly_c
        , ly_r
        , line_uid
        , ifa
        , referrer_url
        , obref
        , oppref
        , time AS event_time
    FROM
        deduped
    WHERE
        rn = 1
        AND raw_amount IS NOT NULL
    GROUP BY
        event_id, ph, country, member_id
        , client_user_agent, client_ip_address, event_source_url
        , fbc, fbp, ly_su, ly_c, ly_r, line_uid, ifa, referrer_url, obref, oppref, time
)

, with_email AS (
    SELECT
        a.*
        , ${common.member_db && common.member_tbl && common.member_id_col && common.member_email_col && common.col_member_id ? 'm.' + common.member_email_col : 'CAST(NULL AS VARCHAR)'} AS em
    FROM
        aggregated a
    -- 会員マスタ未設定時はJOINしない（Cookie / LINE UIDのみで送る場合）
    ${common.member_db && common.member_tbl && common.member_id_col && common.member_email_col && common.col_member_id ? 'LEFT JOIN ' + common.member_db + '.' + common.member_tbl + ' m ON CAST(a.member_id AS VARCHAR) = CAST(m.' + common.member_id_col + ' AS VARCHAR)' : ''}
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
    , ly_su
    , ly_c
    , ly_r
    , line_uid
    , ifa
    , referrer_url
    , obref
    , oppref
    , value_decimal
FROM
    with_email
