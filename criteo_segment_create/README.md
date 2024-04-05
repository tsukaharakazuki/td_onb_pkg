# Workflowについて
Criteoへのセグメント連携において、TDからセグメントを送信する前にCriteo側にセグメントを先に作成しておく必要があります。このWFでは、セグメント名を指定してセグメント作成します。

# 設定
```
      - name: "セグメント1"
        advertiser_id: 11111
      - name: "セグメント2"
        advertiser_id: 11111
```
`name`の欄に作成したいセグメント名を入力してください。  
`advertiser_id`には送信したいCriteoアカウントのadvertiser_idを入力してください。