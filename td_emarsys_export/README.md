# td_emarsys_export

Treasure Data → SAP Emarsys へのデータ送信テンプレート。送信方式を2系統から選択（併用可）。

| 方式 | 実装 | 設定ファイル |
|------|------|--------------|
| 1. SFTP | `td>` + `result_connection`（TD SFTPコネクタ） | `config/sftp.yml` |
| 2. WebDAV | `td>` → `py>`（Custom Script で Emarsys WebDAV に PUT） | `config/webdav.yml` |

## 構成

```
td_emarsys_export/
├── td_emarsys_export.dig     # エントリポイント
├── config/
│   ├── common.yml            # 送信方式の ON/OFF、TD API エンドポイント
│   ├── sftp.yml              # SFTP 接続設定 + 送信データ定義(targets)
│   └── webdav.yml            # WebDAV 接続設定 + 送信データ定義(targets)
├── query/
│   └── export_select.sql     # 汎用抽出SQL（targets の値で中身を切替）
├── scripts/
│   └── webdav_upload.py      # ジョブ結果をCSV化して WebDAV に PUT
└── docs/                     # 各 config の詳細設定ドキュメント
```

## 詳細設定ドキュメント

| ドキュメント | 内容 |
|--------------|------|
| [docs/config_common.md](docs/config_common.md) | `config/common.yml`: 送信方式の ON/OFF、TD API エンドポイント |
| [docs/config_sftp.md](docs/config_sftp.md) | `config/sftp.yml`: SFTP 接続設定、事前準備、出力仕様、トラブルシューティング |
| [docs/config_webdav.md](docs/config_webdav.md) | `config/webdav.yml`: WebDAV 接続設定、Secrets、Python 仕様、トラブルシューティング |
| [docs/config_targets.md](docs/config_targets.md) | `targets`（送信データ定義）: 各キーの書き方、連絡先/販売データの例 |

## 設計

- `common.yml` の `send_method.sftp / webdav` で方式を切り替える。
- 各方式は `+sftp` / `+webdav` のスコープ内で自分の config を `!include` し、`targets` を `for_each>` で回す。
  同じ `targets` という変数名をスコープごとに持つため、SQL は両方式で共通。
- 送信データを追加するときは `targets` にキーを足すだけ。タスク定義は変更不要。
- 特殊な加工が必要なデータは `query/xxx.sql` を追加し、`query_file: xxx` を指定する
  （SQL 内では `${targets[target].*}` を参照可能）。
- 出力ファイル名は `{file_prefix}_{yyyyMMdd}.csv`。Emarsys の自動インポートのファイル名パターン
  （例 `contacts_*.csv`）と合わせる。

## AI アシスタントで設定する

Treasure AI Studio / Claude Code でこのリポジトリを開くと、Skill [`td-emarsys-export-builder`](../.claude/skills/td-emarsys-export-builder/SKILL.md) が使えます（インストール不要）。
「Emarsys連携を設定したい」などと依頼すると、ヒアリング → テーブル確認 → config 作成 → dry-run 付きのデプロイまでを案内します。

## 事前準備

### 共通（Emarsys 側）
- 連絡先 > データインポート > ファイルのインポート で自動インポートを作成
  （ソース: SFTP or Emarsys WebDAV、ファイル名パターン、フィールドマッピング、一意キー）
- ファイル要件: UTF-8 / CSV / 1行目ヘッダー / 小数点はピリオド
- オプトイン（ID=31）を FALSE→TRUE に変更する操作はインポートではできない

### SFTP
- TD コンソールで SFTP の Authentication を作成し、名前を `sftp.connection_name` に設定

### WebDAV
- Emarsys 管理 > セキュリティ設定 > WebDAV Users でユーザー作成、ディレクトリを `webdav.directory` に設定
- Workflow Secrets を登録

```bash
tdx wf secrets set td_emarsys_export td.apikey=<TD_API_KEY>
tdx wf secrets set td_emarsys_export emarsys.webdav_user=<USER>
tdx wf secrets set td_emarsys_export emarsys.webdav_password=<SECRET>
```

## 注意
- Emarsys は WebDAV を旧方式扱いとしており、新規連携は SFTP / API を推奨している。
- 同日に複数回送信する場合はファイル名が上書きされる（`session_date_compact` 単位）。
