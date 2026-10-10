-- =====================================================================
-- 要注意ルール（専用）: 普段と異なるIPアドレスからのアクセス
-- ---------------------------------------------------------------------
-- 監視期間内に使われたユーザー×IPのうち、その前の history_days 日間に
-- 一度も使われていない組み合わせを報告します
-- （過去にアクセス記録が全くない新規ユーザーは対象外）
-- compare_subnet24: true のとき、IPv4 は /24 単位（例: 203.0.113.x）で比較します
-- =====================================================================
INSERT INTO ${output_db}.${findings_table}${table_suffix}
WITH

-- 監視期間内のユーザー×IP
recent AS (
  SELECT
    user_email,
    ip_address,
    -- 比較用のIP（compare_subnet24: true なら IPv4 の末尾を x にして /24 単位で比較）
    CASE
      WHEN ${caution_special.new_ip_for_user.compare_subnet24} AND ip_address LIKE '%.%.%.%' AND ip_address NOT LIKE '%:%'
        THEN ARRAY_JOIN(SLICE(SPLIT(ip_address, '.'), 1, 3), '.') || '.x'
      ELSE ip_address
    END AS ip_key,
    event_name,
    time
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

-- それより前 history_days 日間のユーザー×IP
past AS (
  SELECT DISTINCT
    user_email,
    -- 比較用のIP（compare_subnet24: true なら IPv4 の末尾を x にして /24 単位で比較）
    CASE
      WHEN ${caution_special.new_ip_for_user.compare_subnet24} AND ip_address LIKE '%.%.%.%' AND ip_address NOT LIKE '%:%'
        THEN ARRAY_JOIN(SLICE(SPLIT(ip_address, '.'), 1, 3), '.') || '.x'
      ELSE ip_address
    END AS ip_key
  FROM
    ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time,
      ${session_unixtime - lookback_minutes * 60 - caution_special.new_ip_for_user.history_days * 86400},
      ${session_unixtime - lookback_minutes * 60})
    AND user_email IS NOT NULL
    AND ip_address IS NOT NULL
    AND ip_address <> 'internal'
    AND event_name <> 'column_query'
),

past_users AS (
  SELECT DISTINCT user_email FROM past
),

per_event AS (
  SELECT
    r.user_email,
    r.ip_address,
    r.event_name,
    COUNT(1)    AS cnt,
    MIN(r.time) AS first_time,
    MAX(r.time) AS last_time
  FROM recent r
  JOIN past_users pu ON r.user_email = pu.user_email      -- 過去に記録があるユーザーのみ
  LEFT JOIN past p   ON r.user_email = p.user_email AND r.ip_key = p.ip_key
  WHERE p.user_email IS NULL                              -- そのIPは初めて
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
  'new_ip_for_user'                                 AS rule_id,
  '${caution_special.new_ip_for_user.title}'        AS rule_title,
  '${caution_special.new_ip_for_user.severity}'     AS severity,
  CASE '${caution_special.new_ip_for_user.severity}'
    WHEN 'critical' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 ELSE 4
  END                                               AS severity_rank,
  user_email,
  ip_address,
  event_summary,
  event_count,
  TD_TIME_STRING(first_time, 's!', 'JST')           AS first_event_at,
  TD_TIME_STRING(last_time, 's!', 'JST')            AS last_event_at,
  '過去${caution_special.new_ip_for_user.history_days}日間に使われていないIPからのアクセスです。'  AS detail,
  '${alert_mode}|new_ip_for_user|' || user_email || '|' || ip_address        AS finding_key,
  '${session_time}'                                 AS session_time,
  ${session_unixtime}                               AS time
FROM per_user_ip
