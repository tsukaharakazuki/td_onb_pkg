-- 通知済みテーブル（findings のうち、実際に通知したもの）
-- 再通知抑止（cooldown）の判定に使います
CREATE TABLE IF NOT EXISTS ${output_db}.${notifications_table}${table_suffix} (
  run_id          bigint,   -- ワークフローの attempt_id
  run_env         varchar,  -- prod / dev
  alert_mode      varchar,  -- emergency / caution / custom
  rule_id         varchar,  -- 検知ルールのID
  rule_title      varchar,  -- 検知ルールの表示名
  severity        varchar,  -- critical / high / medium / low
  severity_rank   bigint,   -- 並び替え用（1=critical ... 4=low）
  user_email      varchar,
  ip_address      varchar,
  event_summary   varchar,  -- 例: job_issue×12 / job_result_download×3
  event_count     bigint,
  first_event_at  varchar,  -- JST
  last_event_at   varchar,  -- JST
  detail          varchar,  -- 検知理由などの補足
  finding_key     varchar,  -- 再通知抑止用のキー（モード|ルール|ユーザー|IP）
  session_time    varchar,
  time            bigint    -- ワークフローの session_unixtime
)
