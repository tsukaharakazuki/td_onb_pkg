# config/common.yml 詳細設定

ワークフロー全体の共通設定です。送信方式の ON/OFF と、WebDAV 送信時に使う TD API エンドポイントを定義します。

## 設定例

```yaml
send_method:
  sftp: true
  webdav: false

td_api_endpoint: "https://api.treasuredata.co.jp"
```

## パラメータ一覧

| キー | 型 | 必須 | 既定値（テンプレート） | 説明 |
|------|----|------|------------------------|------|
| `send_method.sftp` | boolean | ○ | `true` | `true` で SFTP コネクタ送信（`+sftp` タスク）を実行 |
| `send_method.webdav` | boolean | ○ | `false` | `true` で WebDAV 直接送信（`+webdav` タスク）を実行 |
| `td_api_endpoint` | string | WebDAV 利用時 ○ | `https://api.treasuredata.co.jp` | Python スクリプトが TD のジョブ結果を取得する API |

### send_method

- 2 つは独立して評価されます。両方 `true` にすると SFTP → WebDAV の順に両方送信します。
- 両方 `false` の場合は `+echo_settings` のみ実行され、何も送信されません（設定確認用）。
- 実行時パラメータ（`-p`）では上書きできません。切り替える場合はこのファイルを編集して `tdx wf push` してください。

### td_api_endpoint

アカウントのリージョンに合わせて設定します。SFTP のみ利用する場合は参照されません。

| リージョン | エンドポイント |
|------------|----------------|
| Tokyo | `https://api.treasuredata.co.jp` |
| US | `https://api.treasuredata.com` |
| EU01 | `https://api.eu01.treasuredata.com` |
| Korea | `https://api.ap02.treasuredata.com` |

## 実行ログでの確認

ワークフロー開始時の `+echo_settings` タスクで、有効な送信方式が出力されます。

```
send_method: sftp=true / webdav=false / session_date=20261011
```

## 関連ドキュメント

- [config/sftp.yml 詳細設定](config_sftp.md)
- [config/webdav.yml 詳細設定](config_webdav.md)
- [送信データ定義（targets）詳細設定](config_targets.md)
