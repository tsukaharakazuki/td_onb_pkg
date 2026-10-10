# auditlog_alert — Treasure Data 監査ログ監視ワークフロー

Treasure Data の **Premium Audit Log**（`td_audit_log.access`）を定期的にチェックし、
情報漏洩・不正アクセスの兆候をメール（＋Slack / Teams / Google Chat）で通知します。

| モード | ワークフロー | 実行間隔 | 内容 |
|---|---|---|---|
| 1. 緊急情報漏洩チェック | `emergency_check.dig` | 10分ごと | ホワイトリスト外IPからのアクセス／休眠ユーザーのログインなし操作／AI・自動化ツールによる探索 |
| 2. 要注意ログ報告 | `caution_daily_report.dig` | 1日1回 | 権限変更・APIキー操作・大量ダウンロード・ログイン失敗・新しいIP・業務時間外操作など |
| 3. 企業別チェック | `custom_check.dig`（週次） / `custom_check_daily.dig`（日次） | 任意 | 企業ごとのチェック。日次は管理者向けおすすめパターン（総当たり成功・APIキー直後の新IP・権限付与直後の大量アクセス など） |
| 開発モード | `dev_run.dig` | 手動 | 本番と同じロジックを開発用テーブル・開発用宛先で実行し、通知内容を確認 |
| 初回セットアップ | `setup_tables.dig` | 最初に1回 | 出力テーブルの作成と、休眠ユーザー判定用の履歴の初期投入 |

> Treasure AI Studio にこのリポジトリを読み込ませると、Skill `auditlog-alert-builder` が
> ヒアリングしながら下記の設定を代行します。AI を使わずに人が設定する場合は、以下の手順どおりに進めてください。

---

## 1. ファイル構成

```
auditlog_alert/
├── emergency_check.dig        # モード1（エントリ）
├── caution_daily_report.dig   # モード2（エントリ）
├── custom_check.dig           # モード3（エントリ）
├── dev_run.dig                # 開発モード（エントリ）
├── setup_tables.dig           # 初回セットアップ（エントリ）
├── sub_*.dig                  # 部品（直接実行しない）
│     sub_emergency / sub_caution / sub_custom … 各モードの処理本体
│     sub_notify                               … 通知（メール・チャット）の共通処理
│     sub_setup                                … テーブル作成
├── config/                    # ★ 設定はすべてここ
│   ├── common.yml               出力DB・アカウント名・除外ユーザーなど
│   ├── send_email_list.yml      メール送信先（全モード共通）
│   ├── dev_send_email_list.yml  開発モードのメール送信先
│   ├── notification.yml         モードごとの件名・監視期間・再通知抑止 / チャット通知の ON・OFF
│   ├── ip_whitelist.yml         IPホワイトリスト（CIDR）
│   ├── emergency_rules.yml      モード1の検知条件
│   ├── caution_rules.yml        モード2の検知ルール
│   ├── custom_checks.yml        モード3のチェック項目
│   └── dev.yml                  開発モードの切り替え
├── queries/                   # SQL（Trino）
│   ├── setup/  emergency/  caution/  custom/  notify/
├── templates/mail_alert.html  # メール本文（HTML）
└── scripts/notify_chat.py     # Teams / Google Chat 送信（Custom Script）
```

## 2. 処理の流れ

```
[各モード]
  ① 検知SQL を実行 → 結果を findings テーブルに追記
  ② 通知対象を確定 → cooldown 内に通知済みの同じ内容を除き notifications テーブルに追記
  ③ 通知メッセージ作成 → SQL で HTML / テキストを1行にまとめる（td.last_results）
  ④ 送信 → メール（必ず） + Slack / Teams / Google Chat（ON のもの）
  ⑤ （モード1のみ）ユーザー×IP の最終アクティビティを activity テーブルに追記
```

出力テーブル（`config/common.yml` の `output_db`）

| テーブル | 内容 |
|---|---|
| `alert_findings` | 検知結果の全件（監査証跡） |
| `alert_notifications` | 実際に通知した内容。メールに載らなかった分もここで確認できます |
| `alert_user_activity` | ユーザー×IP の最終アクティビティ（休眠ユーザー判定用） |

開発モードでは、それぞれ末尾に `_dev` が付いたテーブルを使います。

---

## 3. セットアップ手順

### 3-1. 前提
- Premium Audit Log が有効で、`td_audit_log.access` にデータがあること
- Teams / Google Chat に送る場合は Custom Script が利用可能なこと

### 3-2. 設定ファイルを編集

1. **`config/common.yml`** — `output_db`、`account_label`、`console_url`（リージョン）、`exclude_users`
2. **`config/send_email_list.yml`** — メール送信先（`to` は必須）
3. **`config/ip_whitelist.yml`** — 許可するIPを CIDR で列挙（TD の IP Whitelist と同じ内容が基本）
4. **`config/notification.yml`** — 使うチャットを `enabled: true` に
5. 必要に応じて **`emergency_rules.yml` / `caution_rules.yml` / `custom_checks.yml`** のしきい値・ルールを調整
6. **`config/dev_send_email_list.yml`** — 開発モードの送信先（自分のアドレス）

### 3-3. プロジェクトを push して Secret を登録

```bash
tdx wf push ./auditlog_alert

# 使うチャットの Webhook URL だけ登録
tdx wf secrets set auditlog_alert slack.webhook_url=https://hooks.slack.com/services/XXX
tdx wf secrets set auditlog_alert teams.webhook_url=https://xxx.logic.azure.com/workflows/...
tdx wf secrets set auditlog_alert google_chat.webhook_url=https://chat.googleapis.com/v1/spaces/...
```

| チャネル | Webhook URL の取得方法 |
|---|---|
| Slack | Slack App の Incoming Webhooks を有効化してチャンネルを選択 |
| Teams | チャンネルの「…」→「ワークフロー」→「Webhook 要求を受信したらチャネルに投稿する」 |
| Google Chat | スペース名 →「アプリと統合」→「Webhook を追加」 |

### 3-4. 初回セットアップを実行

```bash
tdx wf run auditlog_alert.setup_tables
```

### 3-5. 開発モードで通知内容を確認

`config/dev.yml` で実行するモードと監視期間を設定し、push してから実行します。

```bash
tdx wf push ./auditlog_alert
tdx wf run auditlog_alert.dev_run
```

- 各モードの最初のタスク（`+show_settings`）に、実際に使われた設定値が出力されます
- 検知結果は `<output_db>.alert_findings_dev` / `alert_notifications_dev` で確認できます
- `always_notify: true` にすると、検知0件でもメールの見た目を確認できます
- 開発モードの値は `-p` で上書きせず、`config/dev.yml` を編集して push してください

### 3-6. スケジュールを有効化

`emergency_check.dig` / `caution_daily_report.dig` / `custom_check.dig` の `schedule:` のコメントを外して push します。

---

## 4. 検知ルールの詳細

### モード1: 緊急情報漏洩チェック（`config/emergency_rules.yml`）

| ルール | 判定 | 重要度 |
|---|---|---|
| ホワイトリスト外IPからのアクセス | `ip_whitelist.yml` の CIDR に含まれないIPからの操作。ユーザー×IPごとにイベント回数を報告 | 成功した操作あり → 緊急 / ログイン失敗のみ → 高 |
| 休眠ユーザーのログインなし操作 | `dormant_days` 日以上アクセスがなかったユーザーが、直近 `sign_in_grace_hours` 時間ログインせずに重要操作（クエリ・ダウンロード・APIキー・ポリシー変更など） | 重要操作（`critical_events`）を含む → 緊急 / それ以外 → 高 |
| AI・自動化ツールによる探索 | 探索系クエリ（`SELECT 1`, `SHOW TABLES`, `information_schema` など）・1分あたりのイベント数の急増・多数のDB横断・権限エラーの繰り返し | シグナル2つ以上 → 緊急 / 1つ → 高 |

- `ip_address = 'internal'`（TD 内部で実行されたワークフローなど）は常に対象外です
- 同じ内容（ルール×ユーザー×IP）は `cooldown_minutes`（既定120分）の間、再通知しません
- 監査ログの取り込み遅延を吸収するため、毎回 `lookback_minutes`（既定30分）さかのぼって確認します

### モード2: 要注意ログ報告（`config/caution_rules.yml`）

`caution_rules` にイベント名を列挙するだけでルールを追加できます。

```yaml
caution_rules:
  my_new_rule:
    title: "通知に表示する名前"
    severity: medium          # critical / high / medium / low
    events: [event_a, event_b]
    min_count: 1              # ユーザー×IPあたりこの回数以上で報告
    include_internal: false   # TD内部の操作も含めるか
    enabled: true
```

イベント名の一覧: [Premium Audit Log Events](https://docs.treasure.ai/products/control-panel/security/auditlogs/premium-audit-log-events) /
[イベント一覧シート](https://docs.google.com/spreadsheets/d/e/2PACX-1vT3l3vrWjFLp4q6TRaxlG2E7ueDmTm63ov3vPpbiKkeoHvSCbsuwNjNarwO3cSUn4sMtUAJxUfwHr-O/pubhtml)

### モード3: 企業別チェック（`config/custom_checks.yml`）

1. `queries/custom/` に SQL を追加（書き方は `queries/custom/README.md`）
2. `custom_checks` に登録し、`group`（実行スパン）を指定
3. 別スパンで実行する場合は `custom_check.dig` をコピーし、`schedule` と `custom_group` を変更

---

## 5. よくある調整

| 症状 | 対処 |
|---|---|
| 連携サーバー・BIツールの通知が多い | `common.yml` の `exclude_users` にサービスアカウントを追加、または送信元IPを `ip_whitelist.yml` に追加 |
| AI探索の誤検知が多い | `emergency_rules.yml` の `ai_probe` のしきい値を上げる |
| 同じ通知が何度も来る | `notification.yml` の `modes.emergency.cooldown_minutes` を延ばす |
| 「普段と異なるIP」が多い | `caution_rules.yml` の `new_ip_for_user.compare_subnet24: true`（/24 単位で比較） |
| メールに載り切らない | `common.yml` の `mail_max_rows` を増やす（全件は `alert_notifications` で確認可能） |

---

## 6. どのイベントを監視すべきか（管理者向け）

- イベントの種類と「検知したい状態 → 使うイベント」の早見表: `skill/auditlog-alert-builder/references/event-catalog.md`
- 内部不正・外部からの不正アクセスのおすすめ検知パターンと提案セット（ミニマム / スタンダード / ハイセキュリティ）:
  `skill/auditlog-alert-builder/references/recommended-patterns.md`

## 7. Treasure AI Studio 用 Skill

`skill/auditlog-alert-builder/SKILL.md` を Studio の Skill として登録すると、
「監査ログ監視を設定したい」と話しかけるだけで、ヒアリング → config 編集 → 実データでの検知件数試算 → 開発モードでの確認 までを AI が進めます。

## 8. メールの見た目

`docs/mail_preview_sample.html` はダミーデータで作成したメールのプレビューです（ブラウザで開けます）。
