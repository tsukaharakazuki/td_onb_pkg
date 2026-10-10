# 企業別チェック（custom）SQL の書き方

`config/custom_checks.yml` に登録した SQL が、`custom_check.dig` から1件ずつ実行されます。

## ルール
1. 先頭は `INSERT INTO ${output_db}.${findings_table}${table_suffix}` にする
2. SELECT の列は **下の順番・名前のとおり** にする（テーブル定義と同じ）
3. 監視期間は `TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})`
4. config の params は `${custom_checks[check_id].params.<名前>}` で参照できる
5. 0件でもエラーにはならない（そのチェックは「該当なし」になる）

## SELECT の列（コピーして使ってください）
```sql
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
  user_email,                                       -- varchar
  ip_address,                                       -- varchar（不要なら '-'）
  event_summary,                                    -- varchar 例: job_issue×12
  event_count,                                      -- bigint
  first_event_at,                                   -- varchar 例: TD_TIME_STRING(MIN(time), 's!', 'JST')
  last_event_at,                                    -- varchar
  detail,                                           -- varchar 補足説明
  '${alert_mode}|${check_id}|' || user_email        AS finding_key,
  '${session_time}'                                 AS session_time,
  ${session_unixtime}                               AS time
```

## 動作確認
`config/dev.yml` の `run_custom: true` / `custom_group` を設定して `dev_run.dig` を実行すると、
`config/dev_send_email_list.yml` 宛てに通知が届きます。
