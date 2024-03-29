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

# その他ツールへのメッセージ送信
Workflowではさまざまなツールにデータを送信することが可能です。以下の記事を参考に設定してください。
  
1. Teams
```
+teams:
  http>: https://aaaaa.webhook.office.com/XXXXXXXXX/
  method: POST
  content: |
    {"type":"message","attachments":[
     {"contentType":"application/vnd.microsoft.card.adaptive","contentUrl":null,"content":
       {
         "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
         "type": "AdaptiveCard",
         "version": "1.0",
         "body": [
           {
             "type": "Container",
             "items": [
               {
                 "type": "TextBlock",
                 "text": "Workflow Failure Alert",
                 "weight": "bolder",
                 "size": "medium"
               },
             ]
           },
           {
             "type": "Container",
             "items": [
               {
                 "type": "TextBlock",
                 "text": "please re run teams_api_test",
                 "wrap": true
               },
               {
    "type": "FactSet",
                 "facts": [
                   {
                     "title": "workflow_name:",
                     "value": "teams_api_test"
                   },
                   {
                     "title": "session_time:",
                     "value": "${session_local_time}"
                   },
                   {
                     "title": "Console Access:",
                     "value": "[https://console.treasuredata.com/app/workflows/sessions/${session_id}](https://console.treasuredata.com/app/workflows/sessions/${session_id})"
                   },
                   {
                     "title": "Command for Rerun:",
                     "value": "`td wf retry ${attempt_id} --latest-revision --resume`"
                   }
                 ]
               }
             ]
           }
         ]
       }
       }
       ]
    }
  content_format: text
  content_type: application/json
```

2. Chatwork
```
_export:
  td:
    database: chatwork
  chatwork:
    endpoint: https://api.chatwork.com/v2
    room_id: '11111111'

+chatwork:
  http>: ${chatwork.endpoint}/rooms/${chatwork.room_id}/messages
  method: POST
  headers:
    - X-ChatWorkToken: ${secret:chatwork.token}
  content:
    body: |
      ${session_local_time}
      Chatworkへのデータ送信
  content_format: form
```
