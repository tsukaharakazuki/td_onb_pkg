-- =====================================================================
-- おすすめパターン: 1ユーザーが短時間に多数のネットワークからアクセス
-- ---------------------------------------------------------------------
-- 1時間のうちに params.min_networks 個以上の異なるネットワーク（IPv4 は /16 単位）から
-- 操作したユーザーを報告します。アカウントの共有・認証情報（APIキー）の漏洩が疑われます
-- =====================================================================
INSERT INTO ${output_db}.${findings_table}${table_suffix}
WITH

logs AS (
  SELECT
    time,
    user_email,
    ip_address,
    event_name,
    -- 比較用ネットワーク（IPv4 は先頭2オクテット、それ以外はそのまま）
    CASE
      WHEN ip_address LIKE '%.%.%.%' AND ip_address NOT LIKE '%:%'
        THEN ARRAY_JOIN(SLICE(SPLIT(ip_address, '.'), 1, 2), '.') || '.x.x'
      ELSE ip_address
    END AS network
  FROM ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})
    AND user_email IS NOT NULL
    AND ip_address IS NOT NULL
    AND ip_address <> 'internal'
    AND event_name <> 'column_query'
    ${exclude_users.length > 0 ? "AND user_email NOT IN ('" + exclude_users.join("','") + "')" : ""}
),

per_hour AS (
  SELECT
    user_email,
    time / 3600                    AS hour_bucket,
    COUNT(DISTINCT network)        AS networks,
    ARRAY_JOIN(SLICE(ARRAY_AGG(DISTINCT network), 1, 6), ', ') AS network_list,
    COUNT(1)                       AS cnt,
    MIN(time)                      AS first_time,
    MAX(time)                      AS last_time
  FROM logs
  GROUP BY 1, 2
),

worst AS (
  SELECT
    user_email,
    MAX_BY(network_list, networks) AS network_list,
    MAX(networks)                  AS max_networks,
    SUM(cnt)                       AS event_count,
    MIN(first_time)                AS first_time,
    MAX(last_time)                 AS last_time
  FROM per_hour
  WHERE networks >= ${custom_checks[check_id].params.min_networks}
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
  user_email,
  network_list                                      AS ip_address,
  '1時間に最大 ' || CAST(max_networks AS VARCHAR) || ' ネットワーク'       AS event_summary,
  event_count,
  TD_TIME_STRING(first_time, 's!', 'JST')           AS first_event_at,
  TD_TIME_STRING(last_time, 's!', 'JST')            AS last_event_at,
  '短時間に複数の離れたネットワークから操作しています。アカウント共有またはAPIキー漏洩の可能性があります。' AS detail,
  '${alert_mode}|${check_id}|' || user_email        AS finding_key,
  '${session_time}'                                 AS session_time,
  ${session_unixtime}                               AS time
FROM worst
