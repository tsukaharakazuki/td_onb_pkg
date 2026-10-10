-- =====================================================================
-- 緊急ルール3: AI・自動化ツールによる探索とみられる挙動
-- ---------------------------------------------------------------------
-- ユーザーごとに次の4つのシグナルを集計し、1つ以上該当したら報告します
--   探索系クエリ : 接続テスト・スキーマ探索のクエリ（probe_query_patterns に一致）
--   バースト     : 1分間のイベント数の最大値
--   横断アクセス : クエリ対象DBの種類数
--   権限エラー   : 権限のないリソースへのアクセス回数
-- 2つ以上該当 → critical / 1つ → high
-- =====================================================================
INSERT INTO ${output_db}.${findings_table}${table_suffix}
WITH

-- 監視期間内の外部からの操作（TD内部の操作 'internal' と column_query は除外）
logs AS (
  SELECT
    time,
    user_email,
    ip_address,
    event_name,
    resource_name,
    -- クエリ本文を正規化（改行の除去・コメント削除・小文字化）
    CASE WHEN event_name = 'job_issue' AND query_text IS NOT NULL THEN
      LOWER(TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(
          REGEXP_REPLACE(REPLACE(REPLACE(query_text, '\n', CHR(10)), '\t', ' '), '(?s)/\*.*?\*/', ' '),
          '--[^\n]*', ' '),
        '\s+', ' ')))
    END AS query_norm
  FROM
    ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})
    AND user_email IS NOT NULL
    AND ip_address IS NOT NULL
    AND ip_address <> 'internal'
    AND event_name <> 'column_query'
    ${exclude_users.length > 0 ? "AND user_email NOT IN ('" + exclude_users.join("','") + "')" : ""}
),

-- 探索系クエリの判定
flagged AS (
  SELECT
    *,
    COALESCE(REGEXP_LIKE(query_norm, '(${emergency_rules.ai_probe.probe_query_patterns.join(")|(")})'), false) AS is_probe,
    event_name IN ('${emergency_rules.ai_probe.denied_events.join("','")}') AS is_denied
  FROM logs
),

-- 1分あたりのイベント数（バースト判定用）
per_minute AS (
  SELECT user_email, time / 60 AS minute_bucket, COUNT(1) AS cnt
  FROM logs
  GROUP BY 1, 2
),

burst AS (
  SELECT user_email, MAX(cnt) AS max_events_per_minute
  FROM per_minute
  GROUP BY 1
),

-- ユーザーごとのシグナル集計
signals AS (
  SELECT
    f.user_email,
    ARRAY_JOIN(SLICE(ARRAY_AGG(DISTINCT f.ip_address), 1, 3), ', ')                     AS ip_address,
    COUNT(1)                                                                              AS event_count,
    MIN(f.time)                                                                           AS first_time,
    MAX(f.time)                                                                           AS last_time,
    COUNT_IF(f.is_probe)                                                                  AS probe_count,
    MAX(CASE WHEN f.is_probe THEN SUBSTR(f.query_norm, 1, 80) END)                        AS probe_sample,
    COUNT(DISTINCT CASE WHEN f.event_name = 'job_issue' THEN SPLIT_PART(f.resource_name, '.', 1) END) AS distinct_databases,
    COUNT_IF(f.is_denied)                                                                 AS denied_count,
    MAX(b.max_events_per_minute)                                                          AS max_events_per_minute
  FROM flagged f
  JOIN burst b ON f.user_email = b.user_email
  GROUP BY 1
),

-- 各シグナルの該当判定
judged AS (
  SELECT
    *,
    probe_count           >= ${emergency_rules.ai_probe.probe_query_min}          AS hit_probe,
    max_events_per_minute >= ${emergency_rules.ai_probe.burst_events_per_minute}  AS hit_burst,
    distinct_databases    >= ${emergency_rules.ai_probe.distinct_databases_min}   AS hit_cross_db,
    denied_count          >= ${emergency_rules.ai_probe.denied_events_min}        AS hit_denied
  FROM signals
),

-- イベント内訳
per_event AS (
  SELECT user_email, event_name, COUNT(1) AS cnt
  FROM logs
  GROUP BY 1, 2
),

event_summary AS (
  SELECT
    user_email,
    ARRAY_JOIN(SLICE(ARRAY_AGG(event_name || '×' || CAST(cnt AS VARCHAR) ORDER BY cnt DESC), 1, 6), ' / ') AS event_summary
  FROM per_event
  GROUP BY 1
)

SELECT
  ${attempt_id}                                     AS run_id,
  '${run_env}'                                      AS run_env,
  '${alert_mode}'                                   AS alert_mode,
  'ai_probe'                                        AS rule_id,
  'AI・自動化ツールによる探索とみられる挙動'        AS rule_title,
  IF(hit_count >= 2, 'critical', 'high')            AS severity,
  IF(hit_count >= 2, 1, 2)                          AS severity_rank,
  j.user_email,
  j.ip_address,
  e.event_summary,
  j.event_count,
  TD_TIME_STRING(j.first_time, 's!', 'JST')         AS first_event_at,
  TD_TIME_STRING(j.last_time, 's!', 'JST')          AS last_event_at,
  ARRAY_JOIN(FILTER(ARRAY[
    IF(hit_probe,    '探索系クエリ ' || CAST(probe_count AS VARCHAR) || '件（例: ' || COALESCE(probe_sample, '') || '）'),
    IF(hit_burst,    '1分間に最大 ' || CAST(max_events_per_minute AS VARCHAR) || 'イベント'),
    IF(hit_cross_db, CAST(distinct_databases AS VARCHAR) || '個のDBを横断してクエリ'),
    IF(hit_denied,   '権限エラー ' || CAST(denied_count AS VARCHAR) || '件')
  ], x -> x IS NOT NULL), ' / ')                    AS detail,
  '${alert_mode}|ai_probe|' || j.user_email         AS finding_key,
  '${session_time}'                                 AS session_time,
  ${session_unixtime}                               AS time
FROM (
  SELECT
    *,
    IF(hit_probe, 1, 0) + IF(hit_burst, 1, 0) + IF(hit_cross_db, 1, 0) + IF(hit_denied, 1, 0) AS hit_count
  FROM judged
) j
JOIN event_summary e ON j.user_email = e.user_email
WHERE j.hit_count >= 1
