-- =====================================================================
-- 要注意ルール（専用）: 業務時間外（JST）の重要操作
-- ---------------------------------------------------------------------
-- business_hour_start 時 〜 business_hour_end 時 以外（include_weekend: true なら土日も）
-- に行われた重要操作を、ユーザー×IPごとに報告します
-- =====================================================================
INSERT INTO ${output_db}.${findings_table}${table_suffix}
WITH

logs AS (
  SELECT
    time,
    COALESCE(user_email, '(不明なユーザー)') AS user_email,
    COALESCE(ip_address, '-')               AS ip_address,
    event_name,
    -- 曜日（1=月 ... 7=日）
    DAY_OF_WEEK(FROM_UNIXTIME(time) AT TIME ZONE 'Asia/Tokyo')  AS jst_dow,
    HOUR(FROM_UNIXTIME(time) AT TIME ZONE 'Asia/Tokyo')         AS jst_hour
  FROM
    ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})
    AND event_name IN ('${caution_special.off_hours_activity.events.join("','")}')
    AND COALESCE(ip_address, '') <> 'internal'
    ${exclude_users.length > 0 ? "AND COALESCE(user_email, '') NOT IN ('" + exclude_users.join("','") + "')" : ""}
),

off_hours AS (
  SELECT *
  FROM logs
  WHERE
    jst_hour <  ${caution_special.off_hours_activity.business_hour_start}
    OR jst_hour >= ${caution_special.off_hours_activity.business_hour_end}
    ${caution_special.off_hours_activity.include_weekend ? "OR jst_dow IN (6, 7)" : ""}
),

per_event AS (
  SELECT user_email, ip_address, event_name, COUNT(1) AS cnt, MIN(time) AS first_time, MAX(time) AS last_time
  FROM off_hours
  GROUP BY 1, 2, 3
),

per_user_ip AS (
  SELECT
    user_email,
    ip_address,
    ARRAY_JOIN(ARRAY_AGG(event_name || '×' || CAST(cnt AS VARCHAR) ORDER BY cnt DESC), ' / ') AS event_summary,
    SUM(cnt)        AS event_count,
    MIN(first_time) AS first_time,
    MAX(last_time)  AS last_time
  FROM per_event
  GROUP BY 1, 2
)

SELECT
  ${attempt_id}                                     AS run_id,
  '${run_env}'                                      AS run_env,
  '${alert_mode}'                                   AS alert_mode,
  'off_hours_activity'                              AS rule_id,
  '${caution_special.off_hours_activity.title}'     AS rule_title,
  '${caution_special.off_hours_activity.severity}'  AS severity,
  CASE '${caution_special.off_hours_activity.severity}'
    WHEN 'critical' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 ELSE 4
  END                                               AS severity_rank,
  user_email,
  ip_address,
  event_summary,
  event_count,
  TD_TIME_STRING(first_time, 's!', 'JST')           AS first_event_at,
  TD_TIME_STRING(last_time, 's!', 'JST')            AS last_event_at,
  '業務時間（${caution_special.off_hours_activity.business_hour_start}時〜${caution_special.off_hours_activity.business_hour_end}時${caution_special.off_hours_activity.include_weekend ? "・平日" : ""}）外の操作です。' AS detail,
  '${alert_mode}|off_hours_activity|' || user_email || '|' || ip_address     AS finding_key,
  '${session_time}'                                 AS session_time,
  ${session_unixtime}                               AS time
FROM per_user_ip
