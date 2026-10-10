# Audit Log イベントカタログ（ヒアリング説明用）

Premium Audit Log（`td_audit_log.access`）には約600種類のイベントが記録されます。
ユーザーには **「何を検知したいか」→「どのイベントを見るか」** の順で説明してください。全イベントを列挙する必要はありません。

- 公式: https://docs.treasure.ai/products/control-panel/security/auditlogs/premium-audit-log-events
- 全イベント一覧（シート）: https://docs.google.com/spreadsheets/d/e/2PACX-1vT3l3vrWjFLp4q6TRaxlG2E7ueDmTm63ov3vPpbiKkeoHvSCbsuwNjNarwO3cSUn4sMtUAJxUfwHr-O/pubhtml

## 0. まず押さえる共通の列

| 列 | 意味 | 使い方 |
|---|---|---|
| `time` | 発生時刻（unixtime） | 監視期間の絞り込み（`TD_TIME_RANGE`） |
| `user_email` | 操作したユーザー | 誰が行ったか。Audience Studio 系イベントは NULL の場合あり |
| `ip_address` | 操作元IP | **`internal` = TD 内部（スケジュール実行されたワークフロー等）**。外部IPなら人またはAPIからの直接操作 |
| `event_name` | イベント名 | 何をしたか |
| `resource_name` / `target_table` | 操作対象 | クエリは `DB名.ジョブID` の形式 |
| `affected_user` | 影響を受けたユーザー | 権限を付与された人、APIキーの持ち主など |
| `query_text` | 実行したSQL | `job_issue` で記録。探索クエリの検知に使う |
| `bytesize` | データ量 | `job_result_download` で記録（圧縮後サイズ） |
| `mail_to` / `mail_subject` | ワークフローのメール送信先・件名 | `workflow_email_send` で記録 |
| `old_value` / `new_value` | 変更前後の値 | 設定変更系イベント |

> `column_query` は全体の9割以上を占め、IP・ユーザーが空のため監視対象から外します。

## 1. カテゴリ別：何がわかるか・いつ使うか

### ① ログイン・認証（Account / IP）
| イベント | 意味 |
|---|---|
| `sign_in` / `sign_out` | コンソールへのログイン・ログアウト |
| `sign_in_failed` / `sign_in_failed_sso` | ログイン失敗（パスワード誤り・SSO失敗） |
| `sign_in_failed_by_ipwhitelist` | **IP制限によるブロック**（許可外IPからのログイン試行） |
| `sign_in_failed_by_private_connect` | Private Connect 制限によるブロック |
| `password_revalidate(_failed)` / `sso_revalidate(_failed)` | 重要操作前の再認証 |

**こんな時に使う**: 不正ログインの試行、総当たり攻撃、許可外の場所からのアクセス、乗っ取り後のログイン

### ② アカウントのセキュリティ設定
| イベント | 意味 |
|---|---|
| `ip_whitelist_modify` | **IPホワイトリストの追加・削除**（制限の解除にも使われる） |
| `password_policy_modify` | パスワードポリシーの変更 |
| `account_modify` | アカウント設定の変更 |
| `sso_setting_create/update/delete`, `user_disable_sso` など | SSO 設定の変更・無効化 |

**こんな時に使う**: 攻撃者や内部の人が「監視・制限を緩める」操作をしていないか

### ③ ユーザー・APIキー
| イベント | 意味 |
|---|---|
| `user_invite` / `user_invite_accepted` / `user_create` / `user_delete` / `user_modify` | ユーザーの追加・削除・変更 |
| `user_apikey_generate` | **APIキーの発行**（`affected_user` = キーの持ち主） |
| `user_apikey_download` | **APIキーの表示・ダウンロード** |
| `user_apikey_modify` / `user_apikey_delete` | APIキーの変更・削除 |
| `session_invalidation` | セッションの無効化 |
| `impersonate_approve` / `impersonate_revoke` | サポートによる代理ログインの承認 |

**こんな時に使う**: 不要なアカウントの作成、キーの持ち出し、乗っ取り後の「裏口」作り

### ④ 権限・ポリシー（Permission）
| イベント | 意味 |
|---|---|
| `permission_policy_create/modify/delete` | ポリシーの作成・変更・削除 |
| `permission_policy_attach_user` / `detach_user` | **ユーザーへのポリシー付与・解除**（`affected_user` = 付与された人） |
| `permission_modify` / `database_permission_modify` | 権限・DB権限の変更 |
| `role_create` / `role_delete` | ロールの作成・削除 |
| `unauthorized` / `permission_unauthorized_access` / `insufficient_permission` / `column_unauthorized` | **権限エラー**（権限のないリソースへのアクセス試行） |

**こんな時に使う**: 権限の自己昇格、権限付与の直後のデータ持ち出し、見てはいけないデータを探る挙動

### ⑤ クエリ・ジョブ（Job / Query）
| イベント | 意味 |
|---|---|
| `job_issue` | **クエリの実行**（`query_text` にSQL、`resource_name` に `DB名.ジョブID`） |
| `query_run` / `query_create` / `query_modify` / `query_delete` | 保存クエリの実行・作成・変更・削除 |
| `job_kill` / `job_modify` | ジョブの停止・状態変更 |
| `table_preview` | テーブルのプレビュー（コンソールでの閲覧） |

**こんな時に使う**: 大量・広範囲のクエリ、`SELECT 1`/`SHOW TABLES` などAIや自動化ツールによる探索、重要DBへのアクセス

### ⑥ データの持ち出し（Download / Export）
| イベント | 意味 |
|---|---|
| `job_result_download` | **クエリ結果のダウンロード**（`bytesize` = データ量） |
| `job_result_show` | クエリ結果の表示 |
| `job_result_export` / `job_result_export_failed` | **Result Export**（外部システムへの書き出し） |
| `job_result_download_denied` | ダウンロードの拒否（権限不足） |
| `syndication_run` / `syndication_execution_download` | Activation の実行・結果のダウンロード |
| `bulk_import_error_records_download` | インポートエラーレコードのダウンロード |
| `audit_log_download` | **監査ログ自体のダウンロード**（攻撃者による偵察や証跡確認） |

**こんな時に使う**: 情報漏洩の本丸。量・相手先・タイミング（時間外）で見る

### ⑦ 外部接続・データ連携（Connection / Data Transfer）
| イベント | 意味 |
|---|---|
| `connection_create` / `connection_modify` / `connection_delete` | **外部サービスとの接続（Authentication）の作成・変更** |
| `data_transfer_create/run/modify/delete` | データ連携（Import）の作成・実行 |
| `file_upload_import_create` | ローカルファイルのアップロード |

**こんな時に使う**: 新しい「持ち出し先」の作成、不審な取り込み

### ⑧ データベース・テーブル
| イベント | 意味 |
|---|---|
| `database_create/modify/delete` | DBの作成・変更・削除 |
| `table_create/modify/delete` / `table_swap` / `partial_delete_create` | テーブルの作成・変更・削除 |

**こんな時に使う**: データの破壊・証跡隠し（手動の削除に絞るには `ip_address <> 'internal'`）

### ⑨ ワークフロー
| イベント | 意味 |
|---|---|
| `workflow_attempt_create` / `workflow_attempt_kill` | ワークフローの実行・停止 |
| `workflow_project_revision_create` / `workflow_project_delete` | プロジェクトのpush・削除 |
| `workflow_project_secret_create/put/delete` | **シークレットの登録・変更** |
| `workflow_schedule_disable/enable/skip` | スケジュールの停止・再開 |
| `workflow_email_send` | **ワークフローからのメール送信**（`mail_to` に宛先） |
| `workflow_http_call` | ワークフローからのHTTP呼び出し |
| `custom_script_task_starts/ends` | Custom Script の実行 |

**こんな時に使う**: ワークフロー経由の持ち出し（社外へのメール・HTTP）、監視ワークフローの停止

### ⑩ Audience Studio / Journey / Engage / AI Foundry
| 領域 | 代表イベント |
|---|---|
| Audience Studio | `segment_create/modify/delete`, `syndication_create/run`, `customer_show`, `profile_index` |
| Journey | `journey_create/update/pause/resume` |
| Engage | `engage_campaign_create/modify`, `delivery_email_sender_create` |
| AI Foundry | `llm_agent_create`, `llm_integration_create`, `llm_knowledge_base_create`, `llm_chat_create` |

**こんな時に使う**: 顧客プロファイルの個別閲覧（`customer_show`）、配信の無断変更、AIへの外部連携の追加

## 2. 早見表：検知したい状態 → 使うイベント

| 検知したい状態 | 使うイベント | 実装 |
|---|---|---|
| 許可外の場所からのアクセス | 全イベント × `ip_address` | 緊急: `non_whitelist_ip` |
| ログインの総当たり | `sign_in_failed*` → `sign_in` | 企業別: `brute_force_success` / 日次: `sign_in_failure` |
| 乗っ取られた休眠アカウント | 全イベント（最終アクティビティ）× `sign_in` の有無 | 緊急: `dormant_user` |
| AI・ツールによる探索 | `job_issue`（`query_text`）、権限エラー系 | 緊急: `ai_probe` |
| APIキーの持ち出し | `user_apikey_generate/download` → 新しいIPでの操作 | 企業別: `apikey_then_new_ip` / 日次: `apikey_operation` |
| アカウント共有・キー漏洩 | 全イベント × 1時間あたりのネットワーク数 | 企業別: `multi_ip_user` |
| 権限の昇格と悪用 | `permission_policy_attach_user` → `job_issue` / DL | 企業別: `privilege_then_access` / 日次: `permission_change` |
| 大量のデータ持ち出し | `job_result_download`（`bytesize`）, `job_result_export` | 日次: `data_download`, `data_export` / 企業別: `top_downloaders` |
| 新しい持ち出し先 | `connection_create` → `job_result_export` / `syndication_run` | 企業別: `new_connection_export` |
| ワークフローで社外へ送信 | `workflow_email_send`（`mail_to`） | 企業別: `external_mail_send` |
| 監視・制限の解除 | `ip_whitelist_modify`, `password_policy_modify`, SSO系 | 日次: `security_setting_change` |
| 証跡の確認・隠蔽 | `audit_log_download`, 手動の `table_delete` | 日次: `audit_log_download`, `data_deletion` |
| 時間外の不審な操作 | 重要イベント × JSTの時刻 | 日次: `off_hours_activity` |
| 重要データへのアクセス | `job_issue` / `table_preview`（`resource_name` のDB名） | 企業別: `watched_table_access` |
| 特定ユーザーの監視 | 全イベント × ユーザー | 企業別: `watch_list_users` |
| アカウントの棚卸し | `sign_in` の最終日 | 企業別: `inactive_users` |

## 3. ヒアリング時にこのアカウントの実態を見せるクエリ（読み取り専用）

カテゴリごとの直近30日の件数を見せ、データがあるカテゴリから優先して提案します。

```sql
SELECT
  CASE
    WHEN event_name LIKE 'sign_in%' OR event_name LIKE '%revalidate%' THEN '① ログイン・認証'
    WHEN event_name IN ('ip_whitelist_modify','password_policy_modify','account_modify') OR event_name LIKE 'sso_setting%' THEN '② セキュリティ設定'
    WHEN event_name LIKE 'user_%' OR event_name LIKE 'impersonate%' THEN '③ ユーザー・APIキー'
    WHEN event_name LIKE 'permission%' OR event_name LIKE 'role_%' OR event_name IN ('unauthorized','insufficient_permission','column_unauthorized') THEN '④ 権限・ポリシー'
    WHEN event_name IN ('job_result_download','job_result_export','job_result_show','syndication_run','syndication_execution_download','audit_log_download') THEN '⑥ データの持ち出し'
    WHEN event_name LIKE 'job_%' OR event_name LIKE 'query_%' OR event_name = 'table_preview' THEN '⑤ クエリ・ジョブ'
    WHEN event_name LIKE 'connection%' OR event_name LIKE 'data_transfer%' OR event_name LIKE 'file_upload%' THEN '⑦ 外部接続・データ連携'
    WHEN event_name LIKE 'database_%' OR event_name LIKE 'table_%' THEN '⑧ DB・テーブル'
    WHEN event_name LIKE 'workflow%' OR event_name LIKE 'custom_script%' THEN '⑨ ワークフロー'
    ELSE '⑩ その他（Audience Studio / Engage / AI Foundry 等）'
  END AS category,
  COUNT(1) AS events,
  APPROX_DISTINCT(user_email) AS users,
  COUNT_IF(ip_address <> 'internal') AS external_events
FROM td_audit_log.access
WHERE TD_INTERVAL(time, '-30d') AND event_name <> 'column_query'
GROUP BY 1 ORDER BY 1
```
