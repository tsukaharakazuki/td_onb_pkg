-- =====================================================================
-- 企業別チェック例: ダウンロード量の多いユーザー
-- ---------------------------------------------------------------------
-- job_result_download のデータ量（bytesize）合計が params.min_bytes 以上の
-- ユーザーを、多い順に params.top_n 人まで報告します
-- =====================================================================
INSERT INTO ${output_db}.${findings_table}${table_suffix}
WITH

per_user AS (
  SELECT
    user_email,
    ARRAY_JOIN(SLICE(ARRAY_AGG(DISTINCT ip_address), 1, 3), ', ') AS ip_address,
    COUNT(1)                    AS event_count,
    SUM(COALESCE(bytesize, 0))  AS total_bytes,
    MIN(time)                   AS first_time,
    MAX(time)                   AS last_time
  FROM
    ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})
    AND event_name = 'job_result_download'
    AND user_email IS NOT NULL
    ${exclude_users.length > 0 ? "AND user_email NOT IN ('" + exclude_users.join("','") + "')" : ""}
  GROUP BY 1
),

ranked AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY total_bytes DESC) AS rnk
  FROM per_user
  WHERE total_bytes >= ${custom_checks[check_id].params.min_bytes}
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
  ip_address,
  'job_result_download×' || CAST(event_count AS VARCHAR)                    AS event_summary,
  event_count,
  TD_TIME_STRING(first_time, 's!', 'JST')           AS first_event_at,
  TD_TIME_STRING(last_time, 's!', 'JST')            AS last_event_at,
  CAST(rnk AS VARCHAR) || '位 / 合計 ' || FORMAT('%.1f', total_bytes / 1048576.0) || ' MB'  AS detail,
  '${alert_mode}|${check_id}|' || user_email        AS finding_key,
  '${session_time}'                                 AS session_time,
  ${session_unixtime}                               AS time
FROM ranked
WHERE rnk <= ${custom_checks[check_id].params.top_n}
