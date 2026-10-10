-- =====================================================================
-- おすすめパターン: 権限の付与直後に、付与されたユーザーがデータへ大量アクセス
-- ---------------------------------------------------------------------
-- ポリシーの付与・権限変更（付与された人 = affected_user）の後、params.within_hours 時間以内に
-- その人がクエリ・プレビュー・ダウンロード・Export を params.min_events 回以上行ったケースを報告します
-- 付与した人と付与された人が同じ（自分で自分に権限を付与）場合は詳細に明記します
-- =====================================================================
INSERT INTO ${output_db}.${findings_table}${table_suffix}
WITH

grants AS (
  SELECT
    LOWER(affected_user) AS grantee,
    LOWER(user_email)    AS granter,
    time                 AS grant_time,
    event_name           AS grant_event
  FROM ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})
    AND event_name IN ('permission_policy_attach_user', 'permission_modify', 'database_permission_modify')
    AND affected_user LIKE '%@%'
),

-- 付与されたユーザーごとに最初の付与を採用
first_grant AS (
  SELECT
    grantee,
    MIN(grant_time)                                  AS grant_time,
    ARRAY_JOIN(ARRAY_AGG(DISTINCT granter), ', ')    AS granters,
    BOOL_OR(granter = grantee)                       AS is_self_grant
  FROM grants
  GROUP BY 1
),

access AS (
  SELECT LOWER(user_email) AS user_email, ip_address, event_name, time
  FROM ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})
    AND event_name IN ('job_issue', 'table_preview', 'job_result_download', 'job_result_export', 'job_result_show', 'syndication_execution_download')
    AND user_email IS NOT NULL
    AND COALESCE(ip_address, '') <> 'internal'
),

after_grant AS (
  SELECT g.grantee AS user_email, g.granters, g.is_self_grant, g.grant_time, a.ip_address, a.event_name, a.time
  FROM first_grant g
  JOIN access a
    ON  a.user_email = g.grantee
    AND a.time BETWEEN g.grant_time AND g.grant_time + ${custom_checks[check_id].params.within_hours * 3600}
),

per_event AS (
  SELECT user_email, event_name, COUNT(1) AS cnt
  FROM after_grant
  GROUP BY 1, 2
),

per_user AS (
  SELECT
    user_email,
    MAX(granters)      AS granters,
    BOOL_OR(is_self_grant) AS is_self_grant,
    MIN(grant_time)    AS grant_time,
    MAX(time)          AS last_time,
    COUNT(1)           AS event_count,
    ARRAY_JOIN(SLICE(ARRAY_AGG(DISTINCT ip_address), 1, 3), ', ') AS ip_address
  FROM after_grant
  GROUP BY 1
  HAVING COUNT(1) >= ${custom_checks[check_id].params.min_events}
),

summary AS (
  SELECT user_email,
    ARRAY_JOIN(ARRAY_AGG(event_name || '×' || CAST(cnt AS VARCHAR) ORDER BY cnt DESC), ' / ') AS event_summary
  FROM per_event
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
  p.user_email,
  p.ip_address,
  s.event_summary,
  p.event_count,
  TD_TIME_STRING(p.grant_time, 's!', 'JST')         AS first_event_at,
  TD_TIME_STRING(p.last_time, 's!', 'JST')          AS last_event_at,
  IF(p.is_self_grant, '【自分で自分に権限を付与】', '')
    || '付与者: ' || p.granters || ' / 権限付与の直後にデータへ大量アクセスしています。' AS detail,
  '${alert_mode}|${check_id}|' || p.user_email      AS finding_key,
  '${session_time}'                                 AS session_time,
  ${session_unixtime}                               AS time
FROM per_user p
JOIN summary s ON p.user_email = s.user_email
