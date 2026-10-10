-- =====================================================================
-- おすすめパターン: APIキーの発行・ダウンロード直後に、普段と違うIPから利用
-- ---------------------------------------------------------------------
-- APIキーを発行・ダウンロードしたユーザー（キーの持ち主）が、その後 params.within_hours 時間以内に
-- 過去30日間使っていないネットワーク（IPv4 は /24 単位）から操作したケースを報告します
-- キーの持ち主は affected_user（メールアドレス形式の場合）、なければ操作したユーザーです
-- =====================================================================
INSERT INTO ${output_db}.${findings_table}${table_suffix}
WITH

key_events AS (
  SELECT
    LOWER(IF(affected_user LIKE '%@%', affected_user, user_email)) AS key_owner,
    MIN(time) AS key_time,
    ARRAY_JOIN(ARRAY_AGG(DISTINCT event_name), ', ')               AS key_events
  FROM ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})
    AND event_name IN ('user_apikey_generate', 'user_apikey_download')
    AND COALESCE(affected_user, user_email) IS NOT NULL
  GROUP BY 1
),

-- 外部からの操作（比較用ネットワークつき）
activity AS (
  SELECT
    LOWER(user_email) AS user_email,
    ip_address,
    event_name,
    time,
    CASE
      WHEN ip_address LIKE '%.%.%.%' AND ip_address NOT LIKE '%:%'
        THEN ARRAY_JOIN(SLICE(SPLIT(ip_address, '.'), 1, 3), '.') || '.x'
      ELSE ip_address
    END AS network
  FROM ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60 - 30 * 86400}, ${session_unixtime})
    AND user_email IS NOT NULL
    AND ip_address IS NOT NULL
    AND ip_address <> 'internal'
    AND event_name <> 'column_query'
),

-- ユーザー×ネットワークごとの初回利用時刻
first_seen AS (
  SELECT user_email, network, MIN(time) AS first_time
  FROM activity
  GROUP BY 1, 2
),

-- キー発行後の操作のうち、キー発行より後に初めて使われたネットワークからのもの
after_key AS (
  SELECT
    k.key_owner AS user_email,
    k.key_events,
    k.key_time,
    a.ip_address,
    a.event_name,
    a.time
  FROM key_events k
  JOIN activity a
    ON  a.user_email = k.key_owner
    AND a.time BETWEEN k.key_time AND k.key_time + ${custom_checks[check_id].params.within_hours * 3600}
  JOIN first_seen f
    ON  f.user_email = a.user_email
    AND f.network = a.network
  WHERE f.first_time >= k.key_time
),

per_event AS (
  SELECT user_email, ip_address, event_name, COUNT(1) AS cnt
  FROM after_key
  GROUP BY 1, 2, 3
),

per_user_ip AS (
  SELECT
    user_email,
    ip_address,
    MAX(key_events) AS key_events,
    MIN(key_time)   AS key_time,
    COUNT(1)        AS event_count,
    MAX(time)       AS last_time
  FROM after_key
  GROUP BY 1, 2
),

summary AS (
  SELECT user_email, ip_address,
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
  TD_TIME_STRING(p.key_time, 's!', 'JST')           AS first_event_at,
  TD_TIME_STRING(p.last_time, 's!', 'JST')          AS last_event_at,
  p.key_events || ' の後、初めて使われるネットワークから操作しています。発行したキーが第三者に渡っていないか確認してください。' AS detail,
  '${alert_mode}|${check_id}|' || p.user_email || '|' || p.ip_address       AS finding_key,
  '${session_time}'                                 AS session_time,
  ${session_unixtime}                               AS time
FROM per_user_ip p
JOIN summary s ON p.user_email = s.user_email AND p.ip_address = s.ip_address
