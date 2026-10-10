-- =====================================================================
-- おすすめパターン: 要注意ユーザー（退職予定者・委託先・一時アカウントなど）の全操作
-- ---------------------------------------------------------------------
-- params.users に列挙したユーザーの、外部からの操作をすべて報告します
-- =====================================================================
INSERT INTO ${output_db}.${findings_table}${table_suffix}
WITH

logs AS (
  SELECT LOWER(user_email) AS user_email, COALESCE(ip_address, '-') AS ip_address, event_name, time
  FROM ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})
    AND LOWER(user_email) IN ('${custom_checks[check_id].params.users.join("','").toLowerCase()}')
    AND COALESCE(ip_address, '') <> 'internal'
    AND event_name <> 'column_query'
),

per_event AS (
  SELECT user_email, ip_address, event_name, COUNT(1) AS cnt
  FROM logs
  GROUP BY 1, 2, 3
),

per_user_ip AS (
  SELECT
    user_email,
    ip_address,
    ARRAY_JOIN(ARRAY_AGG(event_name || '×' || CAST(cnt AS VARCHAR) ORDER BY cnt DESC), ' / ') AS event_summary,
    SUM(cnt)  AS event_count
  FROM per_event
  GROUP BY 1, 2
),

period AS (
  SELECT user_email, ip_address, MIN(time) AS first_time, MAX(time) AS last_time
  FROM logs
  GROUP BY 1, 2
)

SELECT
  ${attempt_id}                                     AS run_id,
  '${run_env}'                                      AS run_env,
  '${alert_mode}'                                   AS alert_mode,
  '${check_id}'                                     AS rule_id,
  '${custom_checks[check_id].title}'                AS rule_title,
  '${custom_checks[check_id].severity}'             AS severity,
  CASE '${custom_checks[check_id].severity}'
    WHEN 'critical' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 ELSE 4
  END                                               AS severity_rank,
  u.user_email,
  u.ip_address,
  u.event_summary,
  u.event_count,
  TD_TIME_STRING(p.first_time, 's!', 'JST')         AS first_event_at,
  TD_TIME_STRING(p.last_time, 's!', 'JST')          AS last_event_at,
  '要注意ユーザーとして登録されているユーザーの操作です。'                  AS detail,
  '${alert_mode}|${check_id}|' || u.user_email || '|' || u.ip_address       AS finding_key,
  '${session_time}'                                 AS session_time,
  ${session_unixtime}                               AS time
FROM per_user_ip u
JOIN period p ON u.user_email = p.user_email AND u.ip_address = p.ip_address
