-- ユーザー×IP の最終アクティビティ履歴
-- 緊急モードの実行ごとに追記され、休眠ユーザー判定に使います
-- （TD内部の操作 ip_address = 'internal' は含みません）
CREATE TABLE IF NOT EXISTS ${output_db}.${activity_table}${table_suffix} (
  user_email          varchar,
  ip_address          varchar,
  last_activity_time  bigint,   -- 最後に操作した時刻（unixtime）
  last_sign_in_time   bigint,   -- 最後にログインした時刻（unixtime, ログインがなければ NULL）
  event_count         bigint,
  time                bigint    -- 記録した時刻（unixtime）
)
