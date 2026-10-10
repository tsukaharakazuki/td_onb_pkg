---
name: auditlog-alert-builder
description: Use when the user wants to set up, customize, or debug the Treasure Data audit-log alert workflow (auditlog_alert in tsukaharakazuki/td_onb_pkg) — information-leak / unauthorized-access monitoring using Premium Audit Log (td_audit_log.access). Interviews the user about recipients, IP whitelist, notification channels (email always; Slack / Microsoft Teams / Google Chat optional), which modes to run (緊急情報漏洩チェック 10分毎 / 要注意ログ日次レポート / 企業別チェック), thresholds, excluded service accounts and company-specific checks, then edits config/*.yml, verifies rules with read-only tdx queries, and guides setup_tables / dev_run / schedule activation. Trigger on 「監査ログ監視」「AuditLogアラート」「auditlog_alert」「情報漏洩チェック」「不正アクセス検知」「IPホワイトリスト外アクセス」「休眠ユーザー検知」「AIによる接続テスト検知」「要注意ログ」「監査ログをSlack/Teams/Google Chatに通知」「send_email_list.yml」, audit log alert, security monitoring workflow.
---

# Audit Log Alert Builder

Configure the `auditlog_alert` Treasure Workflow for a customer by interviewing them and editing **only `config/*.yml`** (plus optional custom SQL). The workflow logic (digs, queries, templates, scripts) is shared across customers — keep it untouched so humans can diff and maintain it.

- Template: https://github.com/tsukaharakazuki/td_onb_pkg/tree/main/auditlog_alert
- Event reference: https://docs.treasure.ai/products/control-panel/security/auditlogs/premium-audit-log-events

## Step 1. Fetch the template

Clone into a new folder under the cwd (never overwrite an existing folder):

```bash
git clone --depth 1 https://github.com/tsukaharakazuki/td_onb_pkg.git .td_onb_pkg_src
cp -R .td_onb_pkg_src/auditlog_alert ./auditlog_alert_<customer>
```

Read `README.md` and every file in `config/` before editing, so you follow the current template.

## Step 2. Check prerequisites (read-only)

```bash
tdx describe td_audit_log.access
tdx query "SELECT event_name, count(1) c FROM td_audit_log.access WHERE td_interval(time,'-1d') GROUP BY 1 ORDER BY 2 DESC LIMIT 20"
```

If the table is missing, Premium Audit Log is not enabled — stop and tell the user. Also identify noisy external users (likely service accounts / BI tools) to propose for `exclude_users`:

```bash
tdx query "SELECT user_email, count(1) c, approx_distinct(ip_address) ips FROM td_audit_log.access WHERE td_interval(time,'-1d') AND ip_address <> 'internal' AND event_name <> 'column_query' GROUP BY 1 ORDER BY 2 DESC LIMIT 10"
```

## Step 3. Interview (ask together in one message)

| # | Question | Writes to |
|---|---|---|
| 1 | アカウント表示名 / リージョン（US・東京・EU） | `common.yml` `account_label`, `console_url` |
| 2 | メール送信先 to / cc / bcc（必須） と、開発モードの送信先 | `send_email_list.yml`, `dev_send_email_list.yml` |
| 3 | 追加チャネル: Slack / Teams / Google Chat のどれを使うか | `notification.yml` `notification.*.enabled` |
| 4 | 許可IP（オフィス・VPN・連携サーバー）を CIDR で | `ip_whitelist.yml` |
| 5 | 使うモード（緊急 / 日次 / 企業別）と実行時刻 | 各エントリ dig の `schedule:` |
| 6 | 除外するサービスアカウント（Step 2 の候補を提示） | `common.yml` `exclude_users` |
| 7 | 企業固有で見たい項目（重要DB、特定ユーザー、期間） | `custom_checks.yml` + `queries/custom/*.sql` |
| 8 | 休眠の定義（既定30日）、再通知抑止（既定120分）を変えるか | `emergency_rules.yml`, `notification.yml` |

Defaults are sensible — if the user has no preference, keep them and say so.

## Step 4. Edit the config

- Edit YAML in place, keeping the existing comments. Humans maintain these files without AI.
- Put lists of values (users, CIDRs, event names) in YAML lists — the SQL joins them.
- Never write webhook URLs into files. Give the user the secret commands instead:
  ```bash
  tdx wf secrets set <project> slack.webhook_url=...
  tdx wf secrets set <project> teams.webhook_url=...
  tdx wf secrets set <project> google_chat.webhook_url=...
  ```
- For a company-specific check, copy an example in `queries/custom/` and follow `queries/custom/README.md`. Keep the 17 output columns in the same order, and don't put `${` inside SQL comments (digdag evaluates them).
- To run checks at another interval, copy `custom_check.dig`, then change `schedule` and `custom_group`.

## Step 5. Verify rules with read-only queries

Before pushing, dry-run each detection SQL as a SELECT. Substitute the `${...}` values by hand, drop the `INSERT INTO` line, and wrap the query in `SELECT rule_id, severity, count(1) ... GROUP BY 1,2`. Report the expected volume per day. If a rule would fire dozens of times a day, propose an exclusion or a threshold change before activating it. Present aggregates only; don't dump raw emails or IPs.

## Step 6. Deploy and test (confirm before each run)

1. `tdx wf push ./auditlog_alert_<customer>` (confirm the project name)
2. `tdx wf run <project>.setup_tables` — creates tables and backfills 90 days of activity
3. Edit `config/dev.yml` (modes, lookback, `always_notify`), push, then `tdx wf run <project>.dev_run`. Mail goes only to `dev_send_email_list.yml`, and results go to the `*_dev` tables.
4. Have the user check the received mail and chat. Debug with `tdx wf timeline` and attempt logs; the `+show_settings` echo shows the effective values.
5. Uncomment `schedule:` in the entry digs that are in use, then push.

`tdx wf run` sends real notifications. Explain the scope (which recipients and channels) and wait for explicit approval before every run. Don't rely on `-p` overrides; switch behavior via `config/dev.yml`.

## Output: setup summary

```
## auditlog_alert 設定サマリー（<customer>）
- メール: to=… / cc=…（開発: …）
- チャット: Slack ✅ / Teams ❌ / Google Chat ✅（Secret 登録: 要）
- モード: 緊急(10分) ✅ / 日次 09:00 ✅ / 企業別 weekly ✅
- ホワイトリスト: N件  除外ユーザー: N件
- 想定通知量（直近の実データで試算）: 緊急 x件/日, 日次 y件
- 次の手順: push → setup_tables → dev_run → schedule 有効化
```

## Edge cases

- **Whitelist empty** → rule 1 is skipped automatically. Warn the user that IP-based detection is off.
- **`ip_address = 'internal'`** = TD-internal (scheduled workflows); always excluded. A dormant user whose old workflows still run will not trigger.
- **AI-probe false positives** come from BI tools issuing `SELECT 1` or `SHOW COLUMNS`. Exclude those accounts, or raise `probe_query_min`.
- **`bytesize`** on downloads is compressed msgpack size, so set download thresholds low (MB, not GB).
- **Teams**: the webhook must come from Teams Workflows ("Post to a channel when a webhook request is received"). Legacy Office 365 connector URLs are retired.
