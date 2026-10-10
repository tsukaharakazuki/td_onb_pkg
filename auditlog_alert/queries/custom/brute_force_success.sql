-- =====================================================================
-- おすすめパターン: ログイン失敗の連続 → その後ログイン成功（パスワード総当たりの成功）
-- ---------------------------------------------------------------------
-- 同じユーザー×IPで、ログイン失敗が params.min_failures 回以上続いたあと、
-- params.within_minutes 分以内にログインに成功したケースを報告します
-- =====================================================================
INSERT INTO ${output_db}.${findings_table}${table_suffix}
WITH

fails AS (
  SELECT
    LOWER(user_email) AS user_email,
    ip_address,
    COUNT(1)  AS fail_count,
    MIN(time) AS first_fail,
    MAX(time) AS last_fail
  FROM ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})
    AND event_name IN ('sign_in_failed', 'sign_in_failed_sso', 'sign_in_failed_by_ipwhitelist', 'password_revalidate_failed', 'sso_revalidate_failed')
    AND user_email IS NOT NULL
  GROUP BY 1, 2
  HAVING COUNT(1) >= ${custom_checks[check_id].params.min_failures}
),

successes AS (
  SELECT LOWER(user_email) AS user_email, ip_address, time
  FROM ${audit_db}.${audit_table}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime - lookback_minutes * 60}, ${session_unixtime})
    AND event_name IN ('sign_in', 'sso_revalidate')
    AND user_email IS NOT NULL
),

matched AS (
  SELECT
    f.user_email,
    f.ip_address,
    f.fail_count,
    f.first_fail,
    MIN(s.time) AS success_time
  FROM fails f
  JOIN successes s
    ON  f.user_email = s.user_email
    AND f.ip_address = s.ip_address
    AND s.time BETWEEN f.first_fail AND f.last_fail + ${custom_checks[check_id].params.within_minutes * 60}
  GROUP BY 1, 2, 3, 4
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
  ip_address,
  'ログイン失敗×' || CAST(fail_count AS VARCHAR) || ' → sign_in'            AS event_summary,
  fail_count + 1                                    AS event_count,
  TD_TIME_STRING(first_fail, 's!', 'JST')           AS first_event_at,
  TD_TIME_STRING(success_time, 's!', 'JST')         AS last_event_at,
  'ログイン失敗を繰り返した後に成功しています。本人の操作か確認し、心当たりがなければパスワード変更・セッション無効化を実施してください。' AS detail,
  '${alert_mode}|${check_id}|' || user_email || '|' || ip_address           AS finding_key,
  '${session_time}'                                 AS session_time,
  ${session_unixtime}                               AS time
FROM matched
