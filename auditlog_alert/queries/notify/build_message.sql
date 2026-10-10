-- =====================================================================
-- 通知メッセージの作成
-- ---------------------------------------------------------------------
-- 今回の通知対象（notifications の run_id = 今回）から、メール用HTMLとチャット用テキストを
-- 1行にまとめて返します。結果は store_last_results により td.last_results.（列名） で参照できます
--   should_send  : 通知を送るか（検知あり、または send_when_no_findings = true）
--   subject      : 件名
--   summary_html : 重要度別件数の表（メール用）
--   rows_html    : 検知内容のカード（メール用・最大 mail_max_rows 件）
--   text_body    : 検知内容のテキスト（Slack / Teams / Google Chat 用・最大 chat_max_rows 件）
-- =====================================================================
WITH

-- 今回の通知対象
targets AS (
  SELECT *
  FROM ${output_db}.${notifications_table}${table_suffix}
  WHERE
    TD_TIME_RANGE(time, ${session_unixtime}, ${session_unixtime + 1})
    AND run_id = ${attempt_id}
    AND alert_mode = '${alert_mode}'
),

-- 表示用に整形（HTMLエスケープ・重要度の表示名と色）
formatted AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY severity_rank, event_count DESC, user_email) AS rn,
    severity,
    severity_rank,
    CASE severity WHEN 'critical' THEN '緊急' WHEN 'high' THEN '高' WHEN 'medium' THEN '中' ELSE '低' END AS severity_label,
    CASE severity WHEN 'critical' THEN '#D93025' WHEN 'high' THEN '#E8710A' WHEN 'medium' THEN '#F9AB00' ELSE '#494FFF' END AS severity_color,
    rule_title,
    user_email,
    ip_address,
    event_summary,
    first_event_at,
    last_event_at,
    COALESCE(detail, '') AS detail,
    -- HTMLエスケープ
    REPLACE(REPLACE(REPLACE(rule_title,                  '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS h_rule,
    REPLACE(REPLACE(REPLACE(COALESCE(user_email, '-'),   '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS h_user,
    REPLACE(REPLACE(REPLACE(COALESCE(ip_address, '-'),   '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS h_ip,
    REPLACE(REPLACE(REPLACE(COALESCE(event_summary, ''), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS h_events,
    REPLACE(REPLACE(REPLACE(COALESCE(detail, ''),        '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS h_detail
  FROM targets
),

-- メール用: 検知1件 = 1枚のカード
cards AS (
  SELECT
    rn,
    '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;margin:0 0 12px 0;border:1px solid #cccccc;border-left:6px solid ' || severity_color || ';">'
    || '<tr><td style="padding:12px 14px;font-family:Inter,Arial,sans-serif;font-size:14px;line-height:1.6;color:#333333;">'
    || '<span style="display:inline-block;padding:2px 10px;border-radius:10px;background-color:' || severity_color || ';color:#ffffff;font-size:12px;font-weight:600;">' || severity_label || '</span>'
    || '&nbsp;<strong style="font-size:15px;color:#000000;">' || h_rule || '</strong>'
    || '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-top:8px;font-size:13px;line-height:1.5;">'
    || '<tr><td width="80" style="color:#666666;vertical-align:top;padding:2px 0;">ユーザー</td><td style="padding:2px 0;word-break:break-all;"><strong>' || h_user || '</strong></td></tr>'
    || '<tr><td width="80" style="color:#666666;vertical-align:top;padding:2px 0;">IPアドレス</td><td style="padding:2px 0;word-break:break-all;">' || h_ip || '</td></tr>'
    || '<tr><td width="80" style="color:#666666;vertical-align:top;padding:2px 0;">イベント</td><td style="padding:2px 0;word-break:break-all;">' || h_events || '</td></tr>'
    || '<tr><td width="80" style="color:#666666;vertical-align:top;padding:2px 0;">期間</td><td style="padding:2px 0;">' || first_event_at || ' 〜 ' || last_event_at || '</td></tr>'
    || IF(h_detail <> '', '<tr><td width="80" style="color:#666666;vertical-align:top;padding:2px 0;">詳細</td><td style="padding:2px 0;">' || h_detail || '</td></tr>', '')
    || '</table></td></tr></table>' AS card_html,
    -- チャット用テキスト
    '■ [' || severity_label || '] ' || rule_title || CHR(10)
    || '  ユーザー: ' || COALESCE(user_email, '-') || ' / IP: ' || COALESCE(ip_address, '-') || CHR(10)
    || '  イベント: ' || COALESCE(event_summary, '') || CHR(10)
    || '  期間: ' || first_event_at || ' 〜 ' || last_event_at
    || IF(detail <> '', CHR(10) || '  詳細: ' || detail, '') AS card_text
  FROM formatted
),

-- 件数の集計
counts AS (
  SELECT
    COUNT(1)                          AS finding_count,
    COUNT(DISTINCT user_email)        AS user_count,
    COUNT_IF(severity = 'critical')   AS critical_count,
    COUNT_IF(severity = 'high')       AS high_count,
    COUNT_IF(severity = 'medium')     AS medium_count,
    COUNT_IF(severity = 'low')        AS low_count,
    MIN(severity_rank)                AS top_rank
  FROM targets
),

joined AS (
  SELECT
    ct.*,
    COALESCE(ARRAY_JOIN(ARRAY_AGG(c.card_html ORDER BY c.rn) FILTER (WHERE c.rn <= ${mail_max_rows}), ''), '') AS cards_html,
    COALESCE(ARRAY_JOIN(ARRAY_AGG(c.card_text ORDER BY c.rn) FILTER (WHERE c.rn <= ${chat_max_rows}), CHR(10) || CHR(10)), '') AS cards_text
  FROM counts ct
  LEFT JOIN cards c ON true
  GROUP BY ct.finding_count, ct.user_count, ct.critical_count, ct.high_count, ct.medium_count, ct.low_count, ct.top_rank
)

SELECT
  -- 送信判定
  (finding_count > 0 OR ${send_when_no_findings})   AS should_send,

  -- 件名: [DEV] [緊急] 【緊急】情報漏洩チェック 3件 - Sample Inc.
  '${run_env == "dev" ? dev.subject_prefix : ""}'
  || CASE top_rank WHEN 1 THEN '[緊急] ' WHEN 2 THEN '[高] ' WHEN 3 THEN '[中] ' WHEN 4 THEN '[低] ' ELSE '[検知なし] ' END
  || '${report_title} ' || CAST(finding_count AS VARCHAR) || '件 - ${account_label}'  AS subject,

  finding_count,
  user_count,
  critical_count,
  high_count,
  medium_count,
  low_count,

  -- ヘッダーの色（最も高い重要度の色）
  CASE top_rank WHEN 1 THEN '#D93025' WHEN 2 THEN '#E8710A' WHEN 3 THEN '#F9AB00' WHEN 4 THEN '#494FFF' ELSE '#1E8E3E' END AS header_color,

  -- 監視期間（JST）
  TD_TIME_STRING(${session_unixtime - lookback_minutes * 60}, 's!', 'JST') AS period_from,
  TD_TIME_STRING(${session_unixtime}, 's!', 'JST')                         AS period_to,

  -- メール用: 重要度別件数の表
  '<table width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;border-color:#cccccc;width:100%;">'
  || '<tr>'
  || '<th style="background-color:#f0f0f0;border:1px solid #cccccc;padding:10px 5px;font-family:Inter,Arial,sans-serif;font-size:14px;font-weight:normal;color:#333333;text-align:center;">緊急</th>'
  || '<th style="background-color:#f0f0f0;border:1px solid #cccccc;padding:10px 5px;font-family:Inter,Arial,sans-serif;font-size:14px;font-weight:normal;color:#333333;text-align:center;">高</th>'
  || '<th style="background-color:#f0f0f0;border:1px solid #cccccc;padding:10px 5px;font-family:Inter,Arial,sans-serif;font-size:14px;font-weight:normal;color:#333333;text-align:center;">中</th>'
  || '<th style="background-color:#f0f0f0;border:1px solid #cccccc;padding:10px 5px;font-family:Inter,Arial,sans-serif;font-size:14px;font-weight:normal;color:#333333;text-align:center;">低</th>'
  || '<th style="background-color:#f0f0f0;border:1px solid #cccccc;padding:10px 5px;font-family:Inter,Arial,sans-serif;font-size:14px;font-weight:normal;color:#333333;text-align:center;">対象ユーザー数</th>'
  || '</tr><tr>'
  || '<td style="border:1px solid #cccccc;padding:10px 5px;font-family:Inter,Arial,sans-serif;font-size:18px;font-weight:600;text-align:center;color:#D93025;">' || CAST(critical_count AS VARCHAR) || '</td>'
  || '<td style="border:1px solid #cccccc;padding:10px 5px;font-family:Inter,Arial,sans-serif;font-size:18px;font-weight:600;text-align:center;color:#E8710A;">' || CAST(high_count AS VARCHAR) || '</td>'
  || '<td style="border:1px solid #cccccc;padding:10px 5px;font-family:Inter,Arial,sans-serif;font-size:18px;font-weight:600;text-align:center;color:#F9AB00;">' || CAST(medium_count AS VARCHAR) || '</td>'
  || '<td style="border:1px solid #cccccc;padding:10px 5px;font-family:Inter,Arial,sans-serif;font-size:18px;font-weight:600;text-align:center;color:#494FFF;">' || CAST(low_count AS VARCHAR) || '</td>'
  || '<td style="border:1px solid #cccccc;padding:10px 5px;font-family:Inter,Arial,sans-serif;font-size:18px;font-weight:600;text-align:center;color:#000000;">' || CAST(user_count AS VARCHAR) || '</td>'
  || '</tr></table>' AS summary_html,

  -- メール用: 検知内容のカード
  CASE
    WHEN finding_count = 0 THEN
      '<p style="margin:0;padding:16px;border:1px solid #cccccc;font-family:Inter,Arial,sans-serif;font-size:14px;color:#1E8E3E;text-align:center;">監視期間内に該当するログはありませんでした。</p>'
    ELSE cards_html
      || IF(finding_count > ${mail_max_rows},
            '<p style="margin:0;font-family:Inter,Arial,sans-serif;font-size:13px;color:#666666;">ほか ' || CAST(finding_count - ${mail_max_rows} AS VARCHAR)
            || ' 件は ${output_db}.${notifications_table}${table_suffix}（run_id = ${attempt_id}）で確認できます。</p>', '')
  END AS rows_html,

  -- チャット用: 検知内容のテキスト
  CASE
    WHEN finding_count = 0 THEN '監視期間内に該当するログはありませんでした。'
    ELSE '緊急 ' || CAST(critical_count AS VARCHAR) || ' / 高 ' || CAST(high_count AS VARCHAR)
      || ' / 中 ' || CAST(medium_count AS VARCHAR) || ' / 低 ' || CAST(low_count AS VARCHAR)
      || '（対象ユーザー ' || CAST(user_count AS VARCHAR) || '名）' || CHR(10) || CHR(10)
      || cards_text
      || IF(finding_count > ${chat_max_rows},
            CHR(10) || CHR(10) || 'ほか ' || CAST(finding_count - ${chat_max_rows} AS VARCHAR) || ' 件はメールを確認してください。', '')
  END AS text_body

FROM joined
