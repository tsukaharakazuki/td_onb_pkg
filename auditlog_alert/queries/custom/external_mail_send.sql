-- =====================================================================
-- おすすめパターン: ワークフローから社外ドメインへのメール送信
-- ---------------------------------------------------------------------
-- workflow_email_send の宛先（mail_to / mail_cc / mail_bcc）に、params.internal_domains 以外の
-- ドメインが含まれるものを、ワークフローの作成者ごとに報告します
-- （ワークフローの mail> でデータを社外へ持ち出す経路の監視）
-- ※ 正規の社外送信先は params.allowed_external_domains に追加してください
-- =====================================================================
INSERT INTO ${output_db}.${findings_table}${table_suffix}
WITH

mails AS (
  SELECT
    time,
    COALESCE(user_email, revision_created_user, '(不明なユーザー)') AS user_email,
    COALESCE(target_workflow, resource_name, '-')                  AS workflow_name,
    mail_subject,
    -- 宛先のドメインを取り出す（形式に依存しないよう @ の後ろを抽出）
    REGEXP_EXTRACT_ALL(LOWER(COALESCE(mail_to, '') || ' ' || COALESCE(mail_cc, '') || ' ' || COALESCE(mail_bcc, '')),
                       '@([a-z0-9.-]+[a-z])', 1) AS domains
  FROM ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})
    AND event_name = 'workflow_email_send'
),

external AS (
  SELECT
    *,
    FILTER(domains, d -> NOT CONTAINS(ARRAY['${custom_checks[check_id].params.internal_domains.concat(custom_checks[check_id].params.allowed_external_domains).join("','")}'], d)) AS external_domains
  FROM mails
),

per_user AS (
  SELECT
    user_email,
    COUNT(1)                                                              AS event_count,
    MIN(time)                                                             AS first_time,
    MAX(time)                                                             AS last_time,
    ARRAY_JOIN(SLICE(ARRAY_DISTINCT(FLATTEN(ARRAY_AGG(external_domains))), 1, 5), ', ') AS domains,
    ARRAY_JOIN(SLICE(ARRAY_AGG(DISTINCT workflow_name), 1, 3), ', ')      AS workflows,
    MAX(SUBSTR(mail_subject, 1, 60))                                      AS sample_subject
  FROM external
  WHERE CARDINALITY(external_domains) > 0
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
  '-'                                               AS ip_address,
  'workflow_email_send×' || CAST(event_count AS VARCHAR)                    AS event_summary,
  event_count,
  TD_TIME_STRING(first_time, 's!', 'JST')           AS first_event_at,
  TD_TIME_STRING(last_time, 's!', 'JST')            AS last_event_at,
  '社外ドメイン: ' || domains || ' / ワークフロー: ' || workflows
    || COALESCE(' / 件名例: ' || sample_subject, '') AS detail,
  '${alert_mode}|${check_id}|' || user_email || '|' || domains              AS finding_key,
  '${session_time}'                                 AS session_time,
  ${session_unixtime}                               AS time
FROM per_user
