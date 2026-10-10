---
name: auditlog-alert-builder
description: Use when the user wants to set up, customize, or debug the Treasure Data audit-log alert workflow (auditlog_alert in tsukaharakazuki/td_onb_pkg) — information-leak / unauthorized-access monitoring using Premium Audit Log (td_audit_log.access). Explains in plain language which Audit Log events exist and which to use for each situation, suggests recommended detection patterns for TD administrators (account takeover, leaked API keys, AI/tool probing, insider data exfiltration, privilege abuse, dormant accounts), interviews the user about recipients, IP whitelist, channels (email always; Slack / Microsoft Teams / Google Chat optional), modes (緊急情報漏洩チェック 10分毎 / 要注意ログ日次 / 企業別チェック), thresholds and excluded service accounts, then edits config/*.yml, estimates alert volume with read-only tdx queries, and guides setup_tables / dev_run / schedule activation. Trigger on 「監査ログ監視」「AuditLogアラート」「auditlog_alert」「AuditLogのイベントを知りたい」「どのイベントを監視すべき」「情報漏洩チェック」「不正アクセス検知」「内部不正の検知」「APIキー漏洩」「IPホワイトリスト外アクセス」「休眠ユーザー検知」「AIによる接続テスト検知」「要注意ログ」「監査ログをSlack/Teams/Google Chatに通知」「send_email_list.yml」, audit log alert, security monitoring workflow.
---

# Audit Log Alert Builder

Set up the `auditlog_alert` Treasure Workflow for a customer. First explain what the Audit Log can see, then propose detection patterns, interview the user, and finally edit **only `config/*.yml`** (plus optional custom SQL). The shared logic (digs, queries, templates, scripts) stays untouched so humans can diff and maintain it.

- Template: https://github.com/tsukaharakazuki/td_onb_pkg/tree/main/auditlog_alert
- **`references/event-catalog.md`** — Audit Log events by category in plain Japanese, and a "検知したい状態 → 使うイベント → 実装ルール" table. Read it before Step 3.
- **`references/recommended-patterns.md`** — recommended patterns for TD admins (A: external compromise, B: insider misuse, C: hygiene) and three proposal sets. Read it before Step 4.

## Step 1. Fetch the template

```bash
git clone --depth 1 https://github.com/tsukaharakazuki/td_onb_pkg.git .td_onb_pkg_src
cp -R .td_onb_pkg_src/auditlog_alert ./auditlog_alert_<customer>
```

Never overwrite an existing folder. Read `README.md` and all of `config/` so you follow the current template.

## Step 2. Look at the account (read-only)

1. `tdx describe td_audit_log.access`. If it's missing, Premium Audit Log is not enabled; stop and tell the user.
2. Run the category inventory query in `references/event-catalog.md` §3 (last 30 days, by category: events, users, external events).
3. Find candidates for `exclude_users`, i.e. noisy external accounts such as ETL bots or BI tools:
   ```bash
   tdx query "SELECT user_email, count(1) c, approx_distinct(ip_address) ips FROM td_audit_log.access WHERE td_interval(time,'-1d') AND ip_address <> 'internal' AND event_name <> 'column_query' GROUP BY 1 ORDER BY 2 DESC LIMIT 10"
   ```
4. **Pre-check the IP whitelist before setting it.** An empty or incomplete whitelist produces a flood of alerts on day one (one real setup hit 130 user×IP pairs a day). Run the two queries in README §3-2 "IPホワイトリストの事前確認":
   - top external user×IP pairs
   - IPs shared by 3+ users
   Shared IPs are almost always the office proxy or VPN egress, so propose them as whitelist candidates and confirm each with the user. Heavy single-user IPs are ETL/BI servers: whitelist them, or put the account in `exclude_users` when the IP rotates. After the whitelist is set, run the `non_whitelist_ip` estimate (Step 6) and repeat until the volume is reasonable.

Show aggregates only. Don't paste raw IPs or query text into the chat.

## Step 3. Explain the Audit Log (before asking anything)

Users usually don't know what the Audit Log records, so give a short overview in plain language. Don't list 600 event names.

1. Show the inventory from Step 2 as a 10-row table: category, what it tells you, and this account's 30-day count.
2. Explain the three things people misread most:
   - `ip_address = 'internal'` is TD's own automation (scheduled workflows), not a person.
   - `affected_user` is the person who *received* a permission or API key.
   - `job_issue.query_text` holds the SQL, which is how AI/tool probing is detected.
3. Show the "検知したい状態 → 使うイベント" table (`event-catalog.md` §2). Then ask: **「何を一番防ぎたいですか？」** (e.g. 顧客データの持ち出し / アカウント乗っ取り / 退職者 / 委託先 / AIツールの無断利用).

## Step 4. Suggest patterns, then interview

Based on the answer, introduce the matching patterns from `recommended-patterns.md`, using its structure: A, then B, then C. For each, give 1–2 lines: aim, signal, and what to do when it fires. Then offer the three sets (**ミニマム / スタンダード★ / ハイセキュリティ**) and let the user pick one, or adjust it.

Then ask the remaining settings together in one message:

| # | Question | Writes to |
|---|---|---|
| 1 | アカウント表示名 / リージョン（US・東京・EU） | `common.yml` `account_label`, `console_url` |
| 2 | メール送信先 to / cc / bcc（必須） / 開発モードの送信先 | `send_email_list.yml`, `dev_send_email_list.yml` |
| 3 | 追加チャネル: Slack / Teams / Google Chat | `notification.yml` |
| 4 | 許可IP（オフィス・VPN・連携サーバー）を CIDR で | `ip_whitelist.yml` |
| 5 | 除外するサービスアカウント（Step 2 の候補を提示） | `common.yml` `exclude_users` |
| 6 | 選んだセットに必要な値: 自社メールドメイン(B4)、重要DB(B7)、要注意ユーザー(B8)、業務時間(B6) | `custom_checks.yml`, `caution_rules.yml` |
| 7 | 実行時刻（日次・企業別） | entry digs `schedule:` |

Defaults are sensible. If the user has no preference, keep them and say so.

## Step 5. Edit the config

- Enable or disable rules according to the chosen set:
  - `emergency_rules.*.enabled`
  - `caution_rules.*.enabled` / `caution_special.*.enabled`
  - `custom_checks.*.enabled`
- Daily admin patterns run from `custom_check_daily.dig` (group `daily`).
- Edit YAML in place and keep the comments; humans maintain these files. Put values in YAML lists.
- Never write webhook URLs into files. Give the user the secret commands: `tdx wf secrets set <project> slack.webhook_url=...` (likewise `teams.webhook_url`, `google_chat.webhook_url`).
- If you edit a `.dig`, wrap any `${...}` containing `: ` (e.g. a ternary `a ? b : c`) in double quotes. Otherwise TD's server-side YAML validation rejects the push with `mapping values are not allowed here`, for both `tdx wf push` and `tdx wf upload`; `--skip-validation` doesn't help. For `if>:` conditions, use `&&` / `||` instead of a ternary so no quoting is needed.
- For a company-specific check that doesn't exist yet, copy a file in `queries/custom/` and follow `queries/custom/README.md`. Keep the 17 output columns in order, and never put `${` in SQL comments.

## Step 6. Estimate alert volume (read-only)

For each enabled rule, render its SQL by hand: substitute `${...}`, drop the `INSERT INTO` line, and wrap it in `SELECT count(1) findings, sum(event_count) events FROM (...)`. Use the last 1–7 days. Report the estimated alerts per day for each rule. If a rule exceeds roughly 10 per day, propose a threshold change or `exclude_users` before activating it. Users stop reading noisy alerts.

## Step 7. Deploy and test (confirm before each run)

1. Check `tdx.json` in the project folder. It's bundled with `{"workflow_project": "auditlog_alert"}`, and `tdx wf push` reads the target project name from it. Without it, push fails with `No tdx.json found`. Change `workflow_project` if the user wants another project name. Never copy a `workflow_project_id` from a different environment.
   Then run `tdx wf push --dry-run ./auditlog_alert_<customer>` to check, and `tdx wf push ./auditlog_alert_<customer>`.
2. `tdx wf run <project>.setup_tables` — creates tables and backfills activity history
3. Set `config/dev.yml`, push, then `tdx wf run <project>.dev_run`. Mail goes only to `dev_send_email_list.yml`, and results go to the `*_dev` tables.
4. Check the received mail and chat with the user. Debug with `tdx wf timeline` and attempt logs; `+show_settings` echoes the effective values.
5. Uncomment `schedule:` in the entry digs that are in use, then push.

`tdx wf run` sends real notifications. State the recipients and channels, and wait for explicit approval each time. Don't use `-p` overrides; switch behavior through `config/dev.yml`.

## Output: setup summary

```
## auditlog_alert 設定サマリー（<customer>）
- 目的: <ユーザーが最も防ぎたいこと>
- セット: スタンダード（+ B7 重要DB監視）
- 有効なルール: 緊急 3 / 日次 13+2 / 企業別 daily 5・weekly 2・monthly 1
- 想定通知量: 緊急 約x件/日, 日次レポート y件, 企業別 z件
- メール: to=…（開発: …） / チャット: Slack ✅ Teams ❌ Google Chat ✅（Secret 要登録）
- ホワイトリスト: N件 / 除外ユーザー: N件
- 次の手順: push → setup_tables → dev_run → schedule 有効化
```

## Edge cases

- **Whitelist empty** → A1 is skipped automatically. Warn the user that IP-based detection is off.
- **Whitelist incomplete** → a flood of A1 alerts. Do the Step 2-4 pre-check before enabling the schedule.
- **Push errors**: `No tdx.json found` means recreate `tdx.json`. `mapping values are not allowed here` means an unquoted `${... ? ... : ...}` in a dig (see Step 5).
- **AI-probe false positives** come from BI keep-alive `SELECT 1` or sanctioned AI tools (tdx/MCP). Exclude those accounts or raise `probe_query_min`.
- **`bytesize`** is compressed size, so keep download thresholds in MB.
- **`user_email` is NULL** for some Audience Studio events. User-based rules don't see those events.
- **Teams** webhooks must come from Teams Workflows ("Post to a channel when a webhook request is received"). Office 365 connector URLs are retired.
