# config/webdav.yml 詳細設定

TD のクエリ結果を Custom Script（Python）で CSV 化し、Emarsys が提供する WebDAV フォルダへ直接アップロードする方式の設定です。

`common.yml` の `send_method.webdav: true` のときに読み込まれます。

## 全体の流れ

```
+webdav_query  : td> export_select.sql（結果はTDジョブ結果として保持）
      │ ${td.last_job_id}
      ▼
+webdav_upload : py> scripts/webdav_upload.py
                 ジョブ結果を取得 → UTF-8 CSV 作成 → HTTP PUT
      │
      ▼
https://webdav.emarsys.net/{directory}/{file_prefix}_{yyyyMMdd}.csv
      │
      ▼
Emarsys 自動インポート（約1分ごとにフォルダを確認）
取込後: *.done（成功）/ *.error（失敗）/ *.ignore（パターン不一致）にリネーム
```

## 事前準備

### 1. Emarsys 側: WebDAV ユーザーの作成

1. 管理 > セキュリティ設定 > **WebDAV Users** でユーザーを作成
2. 表示される **ユーザー名・シークレット・ディレクトリ** を控える（シークレットは再表示できない場合があります）

### 2. Emarsys 側: 自動インポートの作成

1. 連絡先 > データインポート > ファイルのインポート > 自動インポートを作成
2. ソースに **Emarsys WebDAV** を選択し、ディレクトリを指定
3. ファイル名パターンを設定（例: `contacts_*.csv`。大文字小文字を区別）
4. サンプル CSV でフィールドマッピング・一意キーを設定し、有効化

### 3. TD 側: Workflow Secrets の登録

ワークフローを push した後、プロジェクトに以下の Secrets を登録します（TD コンソール > Workflows > プロジェクト > Secrets でも可）。

| Secret キー | 内容 |
|-------------|------|
| `td.apikey` | ジョブ結果を取得できる TD API キー（対象 DB を参照できるユーザーのキー） |
| `emarsys.webdav_user` | WebDAV ユーザー名 |
| `emarsys.webdav_password` | WebDAV シークレット |

## 設定例

```yaml
webdav:
  base_url: "https://webdav.emarsys.net"
  directory: "xxxxx_account_dir"
  newline: "CRLF"
  skip_if_empty: true
  timeout_sec: 600

targets:
  contacts:
    ...   # → config_targets.md 参照
```

## パラメータ一覧（webdav）

| キー | 型 | 必須 | 既定値（テンプレート） | 説明 |
|------|----|------|------------------------|------|
| `base_url` | string | ○ | `https://webdav.emarsys.net` | WebDAV のベース URL。末尾スラッシュなし |
| `directory` | string | ○ | `xxxxx_account_dir` | WebDAV Users 画面に表示されるアカウント別ディレクトリ。前後のスラッシュは自動で除去 |
| `newline` | string | ○ | `CRLF` | 改行コード。`CRLF` / `LF` / `CR` |
| `skip_if_empty` | boolean | ○ | `true` | `true`: 抽出結果 0 件ならアップロードしない（ヘッダーのみのファイルを送らない） |
| `timeout_sec` | number | ○ | `600` | PUT のタイムアウト秒数。大きいファイルの場合は延長 |

### アップロード先 URL

```
{base_url}/{directory}/{file_prefix}_{session_date_compact}.csv
例: https://webdav.emarsys.net/xxxxx_account_dir/contacts_20261011.csv
```

## Python スクリプトの仕様（scripts/webdav_upload.py）

| 項目 | 仕様 |
|------|------|
| 実行イメージ | `digdag/digdag-python:3.10` |
| 追加パッケージ | `td-client`, `requests`（実行時に pip install） |
| データ取得 | `td-client` でジョブ結果をストリーミング取得（全件をメモリに載せない） |
| ヘッダー | ジョブ結果のカラム名（= SQL の `AS` 名）を 1 行目に出力 |
| 文字コード | UTF-8（BOM なし） |
| 引用符 | `QUOTE_MINIMAL`（区切り文字・改行・引用符を含む値のみ） |
| NULL | 空文字 |
| 配列/MAP 型 | JSON 文字列に変換 |
| 認証 | HTTP Basic（`WEBDAV_USER` / `WEBDAV_PASSWORD`） |
| 成功判定 | HTTP 200 / 201 / 204 |
| リトライ | 最大 3 回（10 秒・20 秒待機） |

一時ファイル名でアップロードしてからリネームする方式は採用していません。Emarsys はパターンに一致しないファイルを `*.ignore` にリネームすることがあり、リネーム処理が失敗する可能性があるためです。

## 注意事項

- Emarsys は WebDAV を旧方式として扱っており、新規連携では SFTP または API を推奨しています。
- ファイルサイズは 1GB 未満を目安にしてください。超える場合は targets を分割します。
- 同じ日に再実行すると同名ファイルを上書きします（Emarsys が取込済みの場合は `*.done` にリネーム済みのため、新規ファイルとして再取込されます）。

## トラブルシューティング

| 症状 | 確認ポイント |
|------|--------------|
| `HTTP 401` | Secrets の `emarsys.webdav_user` / `emarsys.webdav_password` |
| `HTTP 403` / `404` / `409` | `directory` の値（WebDAV Users 画面の表示と完全一致か） |
| `KeyError: 'TD_API_KEY'` 等 | Secrets 未登録、またはキー名の誤り |
| ジョブ取得で 401/404 | `td_api_endpoint` のリージョン、`td.apikey` の権限 |
| `pip install` で失敗 | 一時的なネットワーク障害。リトライで解消することが多い |
| ファイルが `*.ignore` になる | 自動インポートのファイル名パターンと `file_prefix` の不一致 |
| ファイルが `*.error` になる | Emarsys のインポートログ（ヘッダー名・日付形式・一意キー） |

## 関連ドキュメント

- [config/common.yml 詳細設定](config_common.md)
- [送信データ定義（targets）詳細設定](config_targets.md)
- [SAP Emarsys: WebDAV users](https://help.sap.com/docs/SAP_EMARSYS/5d44574160f44536b0130abf58cb87cc/fdf4ffc174c11014ac40f6d3a3dd1348.html)
