# Audience Studio Time Filer設定

## ペアレントセグメント構成ファイルDL
```
export audienceId=xxxxxxx
export TD_API_KEY=xxxx/xxxxxxxxxxxxxx
export TD_ENDPOINT=api-cdp.treasuredata.com
curl -H "Authorization: TD1 "$TD_API_KEY "https://$TD_ENDPOINT/audiences/$audienceId" | jq | tee audience.json
```
* ハードコーディングしてコマンドを打つことも可能
`curl -H "Authorization: TD1 "_TD_API_KEY_ "https://_TD_ENDPOINT_/audiences/_audienceId_" | jq | tee audience.json`
  
audienceId, TD_API_KEY, TD_ENDPOINTはご利用頂いている環境に合わせて変更が必要です。  
https://docs.treasuredata.com/display/public/PD/Sites+and+Endpoints

## DLしたファイルのデータ型を変更
構成ファイル内に`type`でデータ型が定義されているので変更。  
```
"type": "number"
↓
"type": "timestamp"
```
![bf](https://github.com/tsukaharakazuki/td_onb_pkg/blob/main/audience-studio-time-filter/img/json_bf.png)
## 修正した構成ファイルのアップロード
```
export audienceId=xxxxxxx
export TD_API_KEY=xxxx/xxxxxxxxxxxxxx
export TD_ENDPOINT=api-cdp.treasuredata.com
curl -X PUT -H "Content-Type: application/json" -H "Authorization: TD1 "$TD_API_KEY --data @audience.json "https://$TD_ENDPOINT/audiences/$audienceId"
```
* ハードコーディングしてコマンドを打つことも可能
`curl -X PUT -H "Content-Type: application/json" -H "Authorization: TD1 "_TD_API_KEY_ --data @audience.json "https://_TD_ENDPOINT_/audiences/_audienceId_"`

## 設定完了後のAudience Studio
![filter](https://github.com/tsukaharakazuki/td_onb_pkg/blob/main/audience-studio-time-filter/img/filter.png)
