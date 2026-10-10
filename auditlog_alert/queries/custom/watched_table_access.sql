-- =====================================================================
-- 企業別チェック例: 重要テーブルへのアクセス
-- ---------------------------------------------------------------------
-- params.watched_databases に含まれるDBへのクエリ・プレビュー・ダウンロードを
-- ユーザー×IPごとに報告します（TD内部のワークフロー実行は除外）
-- =====================================================================
INSERT INTO ${output_db}.${findings_table}${table_suffix}
WITH

logs AS (
  SELECT
    time,
    user_email,
    ip_address,
    event_name,
    SPLIT_PART(COALESCE(resource_name, target_table, ''), '.', 1) AS database_name
  FROM
    ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})
    AND event_name IN ('job_issue', 'table_preview', 'job_result_download', 'job_result_export', 'job_result_show')
    AND user_email IS NOT NULL
    AND COALESCE(ip_address, '') <> 'internal'
    ${exclude_users.length > 0 ? "AND user_email NOT IN ('" + exclude_users.join("','") + "')" : ""}
),

matched AS (
  SELECT *
  FROM logs
  WHERE database_name IN ('${custom_checks[check_id].params.watched_databases.join("','")}')
),

per_event AS (
  SELECT user_email, ip_address, event_name, COUNT(1) AS cnt
  FROM matched
  GROUP BY 1, 2, 3
),

per_user_ip AS (
  SELECT
    user_email,
    ip_address,
    COUNT(1)                                         AS event_count,
    MIN(time)                                        AS first_time,
    MAX(time)                                        AS last_time,
    ARRAY_JOIN(ARRAY_AGG(DISTINCT database_name), ', ') AS databases
  FROM matched
  GROUP BY 1, 2
),

summary AS (
  SELECT
    user_email,
    ip_address,
    ARRAY_JOIN(ARRAY_AGG(event_name || '×' || CAST(cnt AS VARCHAR) ORDER BY cnt DESC), ' / ') AS event_summary
  FROM per_event
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
  p.user_email,
  p.ip_address,
  s.event_summary,
  p.event_count,
  TD_TIME_STRING(p.first_time, 's!', 'JST')         AS first_event_at,
  TD_TIME_STRING(p.last_time, 's!', 'JST')          AS last_event_at,
  '対象DB: ' || p.databases                         AS detail,
  '${alert_mode}|${check_id}|' || p.user_email || '|' || p.ip_address        AS finding_key,
  '${session_time}'                                 AS session_time,
  ${session_unixtime}                               AS time
FROM per_user_ip p
JOIN summary s ON p.user_email = s.user_email AND p.ip_address = s.ip_address
