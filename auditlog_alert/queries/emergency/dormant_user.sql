-- =====================================================================
-- 緊急ルール2: 休眠ユーザーの突然の操作
-- ---------------------------------------------------------------------
-- 次の条件をすべて満たすユーザーを報告します
--   1. 監視期間内に、重要な操作（dormant_user.sensitive_events）を外部から実行した
--   2. 監視期間より前、dormant_days 日以上アクセスがなかった
--      （history_days 日間に一度も記録がない場合も対象）
--   3. 直近 sign_in_grace_hours 時間にログインしていない（＝APIキー等で直接操作している）
-- 最終アクティビティは activity_table（緊急モード実行ごとに追記）から判定します
-- =====================================================================
INSERT INTO ${output_db}.${findings_table}${table_suffix}
WITH

-- 1. 監視期間内の重要な操作（TD内部の操作 'internal' は除外）
recent AS (
  SELECT
    time,
    user_email,
    ip_address,
    event_name
  FROM
    ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})
    AND user_email IS NOT NULL
    AND ip_address IS NOT NULL
    AND ip_address <> 'internal'
    AND event_name IN ('${emergency_rules.dormant_user.sensitive_events.join("','")}')
    ${exclude_users.length > 0 ? "AND user_email NOT IN ('" + exclude_users.join("','") + "')" : ""}
),

-- 2. 監視期間より前の最終アクティビティ
history AS (
  SELECT
    user_email,
    MAX(last_activity_time) AS last_activity_time
  FROM
    ${output_db}.${activity_table}${table_suffix}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - emergency_rules.dormant_user.history_days * 86400}, ${session_unixtime})
    AND last_activity_time < ${session_unixtime - lookback_minutes * 60}
  GROUP BY 1
),

-- 履歴テーブルが空（setup_tables.dig 未実行）の場合は、全員が休眠扱いになるのを防ぐため判定しない
history_ready AS (
  SELECT COUNT(1) > 0 AS ready FROM ${output_db}.${activity_table}${table_suffix}
),

-- 3. 直近のログイン
signed_in AS (
  SELECT DISTINCT user_email
  FROM
    ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - emergency_rules.dormant_user.sign_in_grace_hours * 3600}, ${session_unixtime})
    AND event_name IN ('sign_in', 'sso_revalidate', 'heroku_sign_in')
    AND user_email IS NOT NULL
),

-- 条件に合うユーザーの操作を、ユーザー×IP×イベントで集計
per_event AS (
  SELECT
    r.user_email,
    r.ip_address,
    r.event_name,
    COUNT(1)    AS cnt,
    MIN(r.time) AS first_time,
    MAX(r.time) AS last_time,
    MAX(h.last_activity_time) AS last_activity_time
  FROM recent r
  CROSS JOIN history_ready hr
  LEFT JOIN history h   ON r.user_email = h.user_email
  LEFT JOIN signed_in s ON r.user_email = s.user_email
  WHERE
    hr.ready
    AND s.user_email IS NULL
    AND (h.last_activity_time IS NULL
         OR h.last_activity_time < ${session_unixtime - emergency_rules.dormant_user.dormant_days * 86400})
  GROUP BY 1, 2, 3
),

-- ユーザー×IPごとにまとめる
per_user_ip AS (
  SELECT
    user_email,
    ip_address,
    ARRAY_JOIN(ARRAY_AGG(event_name || '×' || CAST(cnt AS VARCHAR) ORDER BY cnt DESC), ' / ') AS event_summary,
    SUM(cnt)                AS event_count,
    MIN(first_time)         AS first_time,
    MAX(last_time)          AS last_time,
    MAX(last_activity_time) AS last_activity_time,
    BOOL_OR(event_name IN ('${emergency_rules.dormant_user.critical_events.join("','")}')) AS has_critical
  FROM per_event
  GROUP BY 1, 2
)

SELECT
  ${attempt_id}                                     AS run_id,
  '${run_env}'                                      AS run_env,
  '${alert_mode}'                                   AS alert_mode,
  'dormant_user'                                    AS rule_id,
  '休眠ユーザーのログインなし操作'                  AS rule_title,
  IF(has_critical, 'critical', 'high')              AS severity,
  IF(has_critical, 1, 2)                            AS severity_rank,
  user_email,
  ip_address,
  event_summary,
  event_count,
  TD_TIME_STRING(first_time, 's!', 'JST')           AS first_event_at,
  TD_TIME_STRING(last_time, 's!', 'JST')            AS last_event_at,
  CASE
    WHEN last_activity_time IS NULL
      THEN '過去${emergency_rules.dormant_user.history_days}日間アクセス記録のないユーザーが、ログインせずに操作しています。'
    ELSE '前回アクセス ' || TD_TIME_STRING(last_activity_time, 'd!', 'JST')
         || '（' || CAST((${session_unixtime} - last_activity_time) / 86400 AS VARCHAR) || '日前）以来のアクセスで、ログインせずに操作しています。'
  END                                               AS detail,
  '${alert_mode}|dormant_user|' || user_email || '|' || ip_address           AS finding_key,
  '${session_time}'                                 AS session_time,
  ${session_unixtime}                               AS time
FROM per_user_ip
