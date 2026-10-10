-- =====================================================================
-- 要注意ルール（共通）: イベント条件型ルール
-- ---------------------------------------------------------------------
-- config/caution_rules.yml の caution_rules を1件ずつ実行します（rule_id がキー）
-- 対象イベントをユーザー×IPごとに集計し、min_count 回以上を報告します
-- =====================================================================
INSERT INTO ${output_db}.${findings_table}${table_suffix}
WITH

logs AS (
  SELECT
    time,
    COALESCE(user_email, '(不明なユーザー)') AS user_email,
    COALESCE(ip_address, '-')               AS ip_address,
    event_name,
    COALESCE(resource_name, target_table, target_user_email, affected_user) AS target_name,
    COALESCE(bytesize, size, 0)             AS bytes
  FROM
    ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})
    AND event_name IN ('${caution_rules[rule_id].events.join("','")}')
    ${caution_rules[rule_id].include_internal ? "" : "AND COALESCE(ip_address, '') <> 'internal'"}
    ${exclude_users.length > 0 ? "AND COALESCE(user_email, '') NOT IN ('" + exclude_users.join("','") + "')" : ""}
),

per_event AS (
  SELECT user_email, ip_address, event_name, COUNT(1) AS cnt
  FROM logs
  GROUP BY 1, 2, 3
),

per_user_ip AS (
  SELECT
    l.user_email,
    l.ip_address,
    COUNT(1)                                                       AS event_count,
    MIN(l.time)                                                    AS first_time,
    MAX(l.time)                                                    AS last_time,
    SUM(l.bytes)                                                   AS total_bytes,
    SLICE(ARRAY_AGG(DISTINCT l.target_name) FILTER (WHERE l.target_name IS NOT NULL), 1, 5) AS sample_targets
  FROM logs l
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
  '${rule_id}'                                      AS rule_id,
  '${caution_rules[rule_id].title}'                 AS rule_title,
  '${caution_rules[rule_id].severity}'              AS severity,
  CASE '${caution_rules[rule_id].severity}'
    WHEN 'critical' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 ELSE 4
  END                                               AS severity_rank,
  p.user_email,
  p.ip_address,
  s.event_summary,
  p.event_count,
  TD_TIME_STRING(p.first_time, 's!', 'JST')         AS first_event_at,
  TD_TIME_STRING(p.last_time, 's!', 'JST')          AS last_event_at,
  ARRAY_JOIN(FILTER(ARRAY[
    IF(CARDINALITY(p.sample_targets) > 0, '対象: ' || ARRAY_JOIN(p.sample_targets, ', ')),
    IF(p.total_bytes > 0, 'データ量: ' || FORMAT('%.1f', p.total_bytes / 1048576.0) || ' MB')
  ], x -> x IS NOT NULL), ' / ')                    AS detail,
  '${alert_mode}|${rule_id}|' || p.user_email || '|' || p.ip_address         AS finding_key,
  '${session_time}'                                 AS session_time,
  ${session_unixtime}                               AS time
FROM per_user_ip p
JOIN summary s ON p.user_email = s.user_email AND p.ip_address = s.ip_address
WHERE p.event_count >= ${caution_rules[rule_id].min_count}
