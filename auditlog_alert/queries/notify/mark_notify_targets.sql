-- =====================================================================
-- 通知対象の確定
-- ---------------------------------------------------------------------
-- 今回の実行で検知した結果（findings）のうち、cooldown_minutes 以内に
-- 同じ finding_key で通知済みのものを除いて notifications に記録します
--   - cooldown_minutes = 0 なら全件を通知対象にします
--   - 同じ session のリトライでは再送します（通知漏れを防ぐため）
-- =====================================================================
INSERT INTO ${output_db}.${notifications_table}${table_suffix}
WITH

current_findings AS (
  SELECT *
  FROM ${output_db}.${findings_table}${table_suffix}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime}, ${session_unixtime + 1})
    AND run_id = ${attempt_id}
    AND alert_mode = '${alert_mode}'
),

recently_notified AS (
  SELECT DISTINCT finding_key
  FROM ${output_db}.${notifications_table}${table_suffix}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - cooldown_minutes * 60}, ${session_unixtime})
    AND alert_mode = '${alert_mode}'
)

SELECT
  c.run_id,
  c.run_env,
  c.alert_mode,
  c.rule_id,
  c.rule_title,
  c.severity,
  c.severity_rank,
  c.user_email,
  c.ip_address,
  c.event_summary,
  c.event_count,
  c.first_event_at,
  c.last_event_at,
  c.detail,
  c.finding_key,
  c.session_time,
  c.time
FROM current_findings c
LEFT JOIN recently_notified r ON c.finding_key = r.finding_key
WHERE r.finding_key IS NULL
