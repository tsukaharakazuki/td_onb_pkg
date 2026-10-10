-- =====================================================================
-- 休眠ユーザー判定用の履歴を追記（緊急モードの最後に実行）
-- ---------------------------------------------------------------------
-- 監視期間内に外部から操作したユーザー×IPの最終アクティビティを記録します
-- =====================================================================
INSERT INTO ${output_db}.${activity_table}${table_suffix}
SELECT
  user_email,
  ip_address,
  MAX(time)                                                                 AS last_activity_time,
  MAX(CASE WHEN event_name IN ('sign_in', 'sso_revalidate') THEN time END)  AS last_sign_in_time,
  COUNT(1)                                                                  AS event_count,
  ${session_unixtime}                                                       AS time
FROM
  ${audit_db}.${audit_table}
WHERE
  TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})
  AND user_email IS NOT NULL
  AND ip_address IS NOT NULL
  AND ip_address <> 'internal'
  AND event_name <> 'column_query'
GROUP BY
  user_email,
  ip_address
