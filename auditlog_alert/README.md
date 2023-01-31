# Workflowについて
このWorkflowは、TreasureDataが提供するAuditLogのイベントを検知し、確認すべきイベントが検知された際にメールやSlackで通知するための処理です。
  
# 設定
デフォルトで検知するイベントは以下の10種類です。
```
DBの変更
データのExport
データのダウンロード
コネクタによるimport
ローカルファイルのアップロード
テーブルの作成
テーブルの削除
ホワイトリストの変更
ログイン
ログイン失敗
```
その他のイベントを追加する場合は、以下を参照して設定してください。  
https://docs.treasuredata.com/display/public/PD/Premium+Audit+Log+Events  
https://docs.google.com/spreadsheets/d/e/2PACX-1vT3l3vrWjFLp4q6TRaxlG2E7ueDmTm63ov3vPpbiKkeoHvSCbsuwNjNarwO3cSUn4sMtUAJxUfwHr-O/pubhtml
　　
## 送信イベント設定
`config/params.yml` で送信するイベントのWhere区と、通知するタイトルを設定します。  
```
db_modifications:
  config:
    - (event_name = 'database_create' OR event_name = 'database_modify' OR event_name = 'database_permission_modify' OR event_name = 'database_delete')
  title: "<!TD-AUDITLOG> DBの変更を検知しました"
```
`config` 検出すべきイベントのWhere区設定  
`title` メールやSlackに通知する際のタイトル設定

## メール送信設定
`config/mail.dig` で送信する宛先(to/cc)を設定します
```
to: 
  - "hoge@hogehoge.com"
cc:
  - "fuga@treasure-data.com"
```

## Slack送信設定
`config/slack.dig` で送信するwebhook_urlとChannelを設定します  
`webhook_url` は `secret` での登録を推奨
```
slack:
  webhook_url: ${secret:slack.webhook_url}
  channel: '#cdp_alert'
```
