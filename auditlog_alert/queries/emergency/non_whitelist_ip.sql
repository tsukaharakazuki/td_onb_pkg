-- =====================================================================
-- 緊急ルール1: ホワイトリスト外IPからのアクセス
-- ---------------------------------------------------------------------
-- config/ip_whitelist.yml の CIDR に含まれないIPからの操作を、ユーザー×IPごとに集計します
--   - ログイン失敗だけ（IP制限でブロック済み） → high
--   - 1件でも成功した操作がある               → critical
-- =====================================================================
INSERT INTO ${output_db}.${findings_table}${table_suffix}
WITH

-- ホワイトリスト（config/ip_whitelist.yml）
whitelist AS (
  SELECT cidr
  FROM UNNEST(ARRAY['${ip_whitelist.cidrs.join("','")}']) AS t(cidr)
),

-- 監視期間内の操作（TD内部の操作 'internal' と column_query は除外）
logs AS (
  SELECT
    time,
    COALESCE(user_email, '(不明なユーザー)') AS user_email,
    ip_address,
    event_name
  FROM
    ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})
    AND ip_address IS NOT NULL
    AND ip_address <> 'internal'
    AND event_name <> 'column_query'
    ${exclude_users.length > 0 ? "AND COALESCE(user_email, '') NOT IN ('" + exclude_users.join("','") + "')" : ""}
),

-- IPごとにホワイトリスト判定（IPとして解釈できない値はホワイトリスト外として扱う）
ip_judge AS (
  SELECT
    l.ip_address,
    COALESCE(BOOL_OR(contains(w.cidr, TRY_CAST(l.ip_address AS IPADDRESS))), false) AS is_whitelisted
  FROM (SELECT DISTINCT ip_address FROM logs) l
  CROSS JOIN whitelist w
  GROUP BY l.ip_address
),

-- ホワイトリスト外の操作を、ユーザー×IP×イベントで集計
per_event AS (
  SELECT
    l.user_email,
    l.ip_address,
    l.event_name,
    COUNT(1)    AS cnt,
    MIN(l.time) AS first_time,
    MAX(l.time) AS last_time
  FROM logs l
  JOIN ip_judge j ON l.ip_address = j.ip_address
  WHERE NOT j.is_whitelisted
  GROUP BY 1, 2, 3
),

-- ユーザー×IPごとにまとめる
per_user_ip AS (
  SELECT
    user_email,
    ip_address,
    ARRAY_JOIN(ARRAY_AGG(event_name || '×' || CAST(cnt AS VARCHAR) ORDER BY cnt DESC), ' / ') AS event_summary,
    SUM(cnt)        AS event_count,
    MIN(first_time) AS first_time,
    MAX(last_time)  AS last_time,
    -- 失敗・拒否以外のイベントが1件でもあれば「成功した操作あり」
    BOOL_OR(NOT (event_name LIKE '%failed%' OR event_name LIKE '%denied%' OR event_name IN ('unauthorized', 'permission_unauthorized_access'))) AS has_success
  FROM per_event
  GROUP BY 1, 2
)

SELECT
  ${attempt_id}                                     AS run_id,
  '${run_env}'                                      AS run_env,
  '${alert_mode}'                                   AS alert_mode,
  'non_whitelist_ip'                                AS rule_id,
  'ホワイトリスト外IPからのアクセス'                AS rule_title,
  IF(has_success, 'critical', 'high')               AS severity,
  IF(has_success, 1, 2)                             AS severity_rank,
  user_email,
  ip_address,
  event_summary,
  event_count,
  TD_TIME_STRING(first_time, 's!', 'JST')           AS first_event_at,
  TD_TIME_STRING(last_time, 's!', 'JST')            AS last_event_at,
  IF(has_success,
     '許可されていないIPから操作が成功しています。APIキー漏洩・不正ログインの可能性があります。',
     '許可されていないIPからのアクセスを拒否しました（ログイン失敗のみ）。')  AS detail,
  '${alert_mode}|non_whitelist_ip|' || user_email || '|' || ip_address       AS finding_key,
  '${session_time}'                                 AS session_time,
  ${session_unixtime}                               AS time
FROM per_user_ip
WHERE event_count >= ${emergency_rules.non_whitelist_ip.min_events}
