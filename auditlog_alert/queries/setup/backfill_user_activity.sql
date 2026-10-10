-- 休眠ユーザー判定用の履歴を、過去の監査ログから初期投入します
-- 対象期間: 過去 emergency_rules.dormant_user.history_days 日
-- 履歴テーブルが空のときだけ投入されるため、何度実行しても重複しません
INSERT INTO ${output_db}.${activity_table}${table_suffix}
SELECT
  user_email,
  ip_address,
  MAX(time)                                                        AS last_activity_time,
  MAX(CASE WHEN event_name IN ('sign_in', 'sso_revalidate') THEN time END) AS last_sign_in_time,
  COUNT(1)                                                         AS event_count,
  MAX(time)                                                        AS time
FROM
  ${audit_db}.${audit_table}
WHERE
  TD_TIME_RANGE(time, ${session_unixtime - emergency_rules.dormant_user.history_days * 86400}, ${session_unixtime})
  AND user_email IS NOT NULL
  AND ip_address IS NOT NULL
  AND ip_address <> 'internal'
  AND event_name <> 'column_query'
  -- 既に履歴がある場合は何もしない
  AND (SELECT COUNT(1) FROM ${output_db}.${activity_table}${table_suffix}) = 0
GROUP BY
  user_email,
  ip_address,
  TD_TIME_STRING(time, 'd!', 'JST')
