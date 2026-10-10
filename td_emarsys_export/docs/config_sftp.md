# config/sftp.yml 詳細設定

TD の SFTP コネクタ（`td>` の `result_connection`）でクエリ結果を SFTP サーバーに出力し、Emarsys の自動インポートで取り込む方式の設定です。

`common.yml` の `send_method.sftp: true` のときに読み込まれます。

## 全体の流れ

```
TD (export_select.sql) ──SFTPコネクタ──▶ SFTPサーバー ◀──定期取得── Emarsys 自動インポート
                                     {base_dir}/{file_prefix}_{yyyyMMdd}.csv
```

## 事前準備

### 1. TD 側: Authentication の作成

1. TD コンソール > Integrations Hub > Catalog で **SFTP**（または SFTP v2）を選択
2. Host / Port / User / 認証方式（パスワード or 秘密鍵）を入力して保存
3. 保存した Authentication 名を `sftp.connection_name` に設定

> 接続情報（ホスト・パスワード・秘密鍵）は Authentication 側で管理し、このファイルには書きません。

### 2. Emarsys 側: 自動インポートの作成

1. 連絡先 > データインポート > ファイルのインポート > 自動インポートを作成
2. ソースに **SFTP** を選択し、パス・ユーザー名・認証方式を入力
3. ファイル名パターンを設定（例: `contacts_*.csv`）
4. サンプル CSV をアップロードしてフィールドマッピング・一意キーを設定し、有効化

> Emarsys の SFTP 自動インポートは、利用者側がホストする SFTP サーバーを参照します。

## 設定例

```yaml
sftp:
  connection_name: "emarsys_sftp"
  user_directory_is_root: true
  base_dir: "/import"
  newline: "CRLF"

targets:
  contacts:
    ...   # → config_targets.md 参照
```

## パラメータ一覧（sftp）

| キー | 型 | 必須 | 既定値（テンプレート） | 説明 |
|------|----|------|------------------------|------|
| `connection_name` | string | ○ | `emarsys_sftp` | TD の Authentication 名 |
| `user_directory_is_root` | boolean | ○ | `true` | `true`: `base_dir` をユーザーのホームディレクトリ基準で解釈 / `false`: サーバーのルート基準（絶対パス） |
| `base_dir` | string | ○ | `/import` | アップロード先ディレクトリ。末尾スラッシュなし。Emarsys 自動インポートに設定したパスと一致させる |
| `newline` | string | ○ | `CRLF` | 改行コード。`CRLF` / `LF` / `CR` |

### user_directory_is_root と base_dir の関係

ユーザー `john`（ホーム `/home/john`）で `/home/john/import/contacts_20261011.csv` に置く場合:

| user_directory_is_root | base_dir |
|------------------------|----------|
| `true` | `/import` |
| `false` | `/home/john/import` |

## dig 内で固定している出力設定

以下は Emarsys の要件に合わせて `td_emarsys_export.dig` 側で固定しています。変更が必要な場合は dig を編集してください。

| result_settings | 値 | 理由 |
|-----------------|----|------|
| `path_prefix` | `${sftp.base_dir}/${targets[target].file_prefix}_${session_date_compact}.csv` | Emarsys のファイル名パターンに一致させる |
| `sequence_format` | `""` | 連番サフィックス（`.000.00` 等）を付けない |
| `rename_file_after_upload` | `true` | 一時ファイル名で書き込み完了後にリネーム。書き込み途中のファイルを Emarsys が取り込むのを防ぐ |
| `header_line` | `true` | Emarsys は 1 行目をヘッダーとして扱う |
| `quote_policy` | `MINIMAL` | 区切り文字・改行・引用符を含む値のみ引用符で囲む |
| `null_string` | `""` | NULL は空文字 |
| `delimiter` | `${targets[target].delimiter}` | targets ごとに指定 |
| `newline` | `${sftp.newline}` | 上記パラメータ |

文字コードはコネクタ既定の UTF-8 で出力されます（Emarsys の SFTP/WebDAV インポートは UTF-8 のみ対応）。

## 出力ファイル名

```
{base_dir}/{file_prefix}_{session_date_compact}.csv
例: /import/contacts_20261011.csv
```

- `session_date_compact` はセッション日付（`yyyyMMdd`、タイムゾーン Asia/Tokyo）
- 同じ日に再実行すると同名ファイルを上書きします
- 1 日に複数回送信する場合は、dig の `path_prefix` に時刻を含めるよう変更してください

## トラブルシューティング

| 症状 | 確認ポイント |
|------|--------------|
| `Authentication failed` | Authentication のユーザー・パスワード/鍵、SFTP サーバーの IP 許可（TD の送信元 IP） |
| `No such file` / 権限エラー | `base_dir` が存在するか、`user_directory_is_root` の解釈が正しいか、書き込み権限 |
| ファイル名に `.000.00` などが付く | `sequence_format: ""` が効いているか。コネクタ種別（SFTP / SFTP v2）で挙動が異なる場合あり |
| Emarsys が取り込まない | ファイル名パターン（大文字小文字区別）、自動インポートのパス、自動インポートが有効か |
| Emarsys で文字化け | 抽出元データの文字コード。出力は UTF-8 |

## 関連ドキュメント

- [config/common.yml 詳細設定](config_common.md)
- [送信データ定義（targets）詳細設定](config_targets.md)
- [TD SFTP Server Export Integration](https://docs.treasure.ai/int/sftp-server-export-integration)
