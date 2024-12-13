# はじめに
このWorkflowgはTreasureDataが持っているConversion API connector(Google/META/Yahoo!/LINE)を利用する場合のデータ送信を一括で実行するためのデータ作成処理からデータ送信までを一括で行う処理Workflowです。

# 更新
### td_capi_online.dig
Datalayer変数などで購買イベントをGA4などに送信している場合、その値をtd-jd-sdkでも取り込み、そのデータを送信することを目的としています。  
まだ購買イベントはJSON形式で入ってくることを想定して、分解した上でデータを作成する処理が入っています。  
そのため、オンラインでのCV情報だけを送信する想定です。

### td_capi_pos.dig
日次取り込みなどで購買データがTDに連携されたデータを送信することを目的としています。  
店舗の購買データなども紐づけて送信することも可能ですが、意図しないコンバージョンがカウントされてしまい場合もあります。  
仮にECでの購買データだけを送りたい場合は、`pos.sql`SQLの条件指定をする必要があります。

# 各種ドキュメントとTips
- Google
  - [TD Document](https://docs.treasuredata.com/articles/#!int/google-enhanced-conversion-via-google-ads-export-integration/q/google/qp/1)

- META
  - [TD Document](https://docs.treasuredata.com/articles/#!int/facebook-conversions-api-export-integration/q/facebook%2520conversions/qp/1/qid/536/qid/537)

- Yahoo!
  - [TD Document](https://docs.treasuredata.com/articles/#!int/yahoo-ads-conversion-export-integration)

- LINE
  - [TD Document](https://docs.treasuredata.com/articles/#!int/line-conversion-export-integration)
  - [deduplication_keyについて](https://conversion-api-docs.linebiz.com/ja/#section/%E9%96%8B%E7%99%BA%E3%82%AC%E3%82%A4%E3%83%89%E3%83%A9%E3%82%A4%E3%83%B3/%E3%82%A4%E3%83%99%E3%83%B3%E3%83%88%E3%81%AE%E9%87%8D%E8%A4%87%E6%8E%92%E9%99%A4%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6)

# 重複削除
それぞれのJavascriptで項目を設定した上で、その値をTDにも送信する必要があります。オーダーIDなど全て共通の値を設定することを推奨いたします。

## META 
https://developers.facebook.com/docs/marketing-api/conversions-api/deduplicate-pixel-and-server-events?locale=ja_JP
`event_id`の設定が必要

## Google
https://support.google.com/google-ads/answer/6386790?hl=ja
`transaction_id`の設定が必要

## Yahoo
`transaction_id`の設定が必要

## LINE
https://conversion-api-docs.linebiz.com/ja/#section/%E9%96%8B%E7%99%BA%E3%82%AC%E3%82%A4%E3%83%89%E3%83%A9%E3%82%A4%E3%83%B3/%E3%82%A4%E3%83%99%E3%83%B3%E3%83%88%E3%81%AE%E9%87%8D%E8%A4%87%E6%8E%92%E9%99%A4%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6

`deduplication_key`の設定が必要

# td-js-sdkで取得することで送信できるcookie
|Platform|cookie|column_name|Memo|
|:--|:--|:--|:--|
|Google|_gcl_aw|gcl_aw|Google conversion linker|
|META|_fbp|fbp|facebook 1st Party cookie|
|META|_fbc|fbc|facebook click ID|
|LINE|__lt__cid|lt_cid|LINE cookie|
|YAHOO|_yjsu_yjad|yjsu_yjad|Yahoo CAPI cookie|
|YAHOO|_ycl_yjad|ycl_yjad|Yahoo YCLID|
|X|_twclid|twclid|X click ID|
  
## Javascript記述
cookieにアクセスするためのget cookieの処理を記述した上で、以下の値をtd setしてください。  
```
td.set('$global', {
  gcl_aw: getCookieByName('_gcl_aw'), //Google conversion linker
  fbp: getCookieByName('_fbp'), //facebook 1st Party cookie
  fbc: getCookieByName('_fbc'), //facebook click ID
  lt_cid: getCookieByName('__lt__cid'),　//LINE cookie
  yjsu_yjad: getCookieByName('_yjsu_yjad'), //Yahoo CAPI cookie
  ycl_yjad: getCookieByName('_ycl_yjad'), //Yahoo YCLID
  twclid: getCookieByName('_twclid') //X click ID
});
```