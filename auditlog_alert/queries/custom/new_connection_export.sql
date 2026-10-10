-- =====================================================================
-- おすすめパターン: 外部接続（Authentication）の新規作成と、同じユーザーによるデータ出力
-- ---------------------------------------------------------------------
-- 監視期間内に connection_create（外部サービスへの接続を作成）を行い、かつ
-- Result Export / Activation 実行 / ダウンロードも行ったユーザーを報告します
-- （新しい持ち出し先を作ってデータを送る経路の監視）
-- =====================================================================
INSERT INTO ${output_db}.${findings_table}${table_suffix}
WITH

logs AS (
  SELECT LOWER(user_email) AS user_email, ip_address, event_name, time, resource_name
  FROM ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})
    AND event_name IN ('connection_create', 'job_result_export', 'syndication_run', 'job_result_download')
    AND user_email IS NOT NULL
),

per_user AS (
  SELECT
    user_email,
    MIN(CASE WHEN event_name = 'connection_create' THEN time END)                 AS connection_time,
    COUNT_IF(event_name = 'connection_create')                                    AS connection_count,
    COUNT_IF(event_name <> 'connection_create')                                   AS output_count,
    ARRAY_JOIN(SLICE(ARRAY_AGG(DISTINCT resource_name) FILTER (WHERE event_name = 'connection_create'), 1, 3), ', ') AS connections,
    ARRAY_JOIN(SLICE(ARRAY_AGG(DISTINCT ip_address) FILTER (WHERE ip_address <> 'internal'), 1, 3), ', ') AS ip_address,
    MAX(time)                                                                     AS last_time
  FROM logs
  GROUP BY 1
),

per_event AS (
  SELECT user_email, event_name, COUNT(1) AS cnt
  FROM logs
  GROUP BY 1, 2
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
  COALESCE(NULLIF(p.ip_address, ''), '-')           AS ip_address,
  s.event_summary,
  p.connection_count + p.output_count               AS event_count,
  TD_TIME_STRING(p.connection_time, 's!', 'JST')    AS first_event_at,
  TD_TIME_STRING(p.last_time, 's!', 'JST')          AS last_event_at,
  '新しい接続: ' || COALESCE(p.connections, '-') || ' / 接続作成と同じ期間にデータを出力しています。送信先が正規のものか確認してください。' AS detail,
  '${alert_mode}|${check_id}|' || p.user_email      AS finding_key,
  '${session_time}'                                 AS session_time,
  ${session_unixtime}                               AS time
FROM per_user p
JOIN summary s ON p.user_email = s.user_email
WHERE p.connection_count > 0 AND p.output_count > 0
