-- =====================================================================
-- 企業別チェック例: 長期間ログインしていないユーザー（アカウント棚卸し候補）
-- ---------------------------------------------------------------------
-- 過去1年間にログイン記録があり、直近 params.inactive_days 日間ログインしていない
-- ユーザーを報告します（※監視期間 lookback ではなく、この SQL 独自の期間で判定）
-- =====================================================================
INSERT INTO ${output_db}.${findings_table}${table_suffix}
WITH

last_sign_in AS (
  SELECT
    user_email,
    MAX(time)   AS last_time,
    MIN(time)   AS first_time,
    COUNT(1)    AS event_count
  FROM
    ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - 365 * 86400}, ${session_unixtime})
    AND event_name IN ('sign_in', 'sso_revalidate')
    AND user_email IS NOT NULL
    ${exclude_users.length > 0 ? "AND user_email NOT IN ('" + exclude_users.join("','") + "')" : ""}
  GROUP BY 1
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
  user_email,
  '-'                                               AS ip_address,
  'sign_in×' || CAST(event_count AS VARCHAR) || '（過去1年）'               AS event_summary,
  event_count,
  TD_TIME_STRING(first_time, 's!', 'JST')           AS first_event_at,
  TD_TIME_STRING(last_time, 's!', 'JST')            AS last_event_at,
  '最終ログインから ' || CAST((${session_unixtime} - last_time) / 86400 AS VARCHAR) || '日経過。不要なアカウントであれば削除を検討してください。' AS detail,
  '${alert_mode}|${check_id}|' || user_email        AS finding_key,
  '${session_time}'                                 AS session_time,
  ${session_unixtime}                               AS time
FROM last_sign_in
WHERE last_time < ${session_unixtime - custom_checks[check_id].params.inactive_days * 86400}
