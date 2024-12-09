# Workflowについて
このWorkflowはAudienceStudioのAttributeに設定するデータをBehaviorデータから作成するWorlflowです。  
## 想定UseCase
- セグメントインサイトの描画用データ
- PredictiveScoringの特徴量データ
- AutoML用の特徴量データ
- 顧客カルテの要素データ
などでの利活用を目的としています。

# プリセット処理
Webログの加工については、よく使われる項目については、集計したいWebログデータを設定することで、以下のデータを自動で作成します。  
セッショナイズをした上で、セッション番号を振ったWebログデータを設定してください。  
参考: https://github.com/tsukaharakazuki/td_onb_pkg/tree/main/agg_weblog_hive  
  
合わせて、TreasureDataが用意しているID Unificationも実行された後のデータで処理することを推奨します。
  
### PV
#### all
任意の期間の総PV
#### season
春・夏・秋・冬それぞれの期間ごとのPV
#### hour_range
深夜・朝・昼・夕・夜それぞれのPV
#### dow
曜日ごとのPV
#### holiday
平日と休日のPV
#### area
首都（東京）とそれ以外からのPV
#### device
スマホ・PCごとのPV

### 流入経路
#### referrer
アプリ・ソーシャル・広告・検索・メール・その他などの経路ごとの初回流入数をカウントします
#### area
Google・META・Instaglamなどのチャネルごとの初回流入数をカウントします

### アパレル企業向け
アパレル企業でよく使われるデータについては、プリセットで準備しています。
#### aw_ss
春夏・秋冬のシーズンごとのPV
#### sale
セール期間のPV
#### proper
定価販売期間のPV

# 処理を追加したい場合
プリセット以外の処理を追加する場合に、よく使われる処理については準備をしています。

### pivot
特定のカラムの中身をグルーピングした上で回数カウントし、PIVOTすることが可能です。
### true_false
PV数など数ではなく、任意の条件に合致するかをtrue/falseで2分類します。  
この処理は、PV数など数を特徴量にした場合、分散しずらい場合などで使用します。
### array
特定のカラムの中身を配列で一つのカラムに集約します。現在セグメントインサイトでは配列カラムに出現する要素をTop10まで表示する機能があります。セグメントにおける購入商品Top10を表示したいなどの場合に使用します。

# 作られるカラム
| カラム名 | 内容 |
----|---- 
|key_id|ユーザーID/Cookie|
|td_pv|PV数|
|td_pv_spring|春のPV数|
|td_pv_summer|夏のPV数|
|td_pv_autumn|秋のPV数|
|td_pv_winter|冬のPV数|
|td_hour_0|0時のPV数|
|td_hour_1|1時のPV数|
|td_hour_2|2時のPV数|
|td_hour_3|3時のPV数|
|td_hour_4|4時のPV数|
|td_hour_5|5時のPV数|
|td_hour_6|6時のPV数|
|td_hour_7|7時のPV数|
|td_hour_8|8時のPV数|
|td_hour_9|9時のPV数|
|td_hour_10|10時のPV数|
|td_hour_11|11時のPV数|
|td_hour_12|12時のPV数|
|td_hour_13|13時のPV数|
|td_hour_14|14時のPV数|
|td_hour_15|15時のPV数|
|td_hour_16|16時のPV数|
|td_hour_17|17時のPV数|
|td_hour_18|18時のPV数|
|td_hour_19|19時のPV数|
|td_hour_20|20時のPV数|
|td_hour_21|21時のPV数|
|td_hour_22|22時のPV数|
|td_hour_23|23時のPV数|
|td_hour_midnight|深夜のPV数|
|td_hour_morning|朝のPV数|
|td_hour_noon|昼のPV数|
|td_hour_afternoon|夕方のPV数|
|td_hour_night|夜のPV数|
|td_pv_sun|日曜日のPV数|
|td_pv_mon|月曜日のPV数|
|td_pv_tue|火曜日のPV数|
|td_pv_wed|水目曜日のPV数|
|td_pv_thu|木曜日のPV数|
|td_pv_fri|金曜日のPV数|
|td_pv_sat|土曜日のPV数|
|td_pv_holiday|休日のPV数|
|td_pv_weekday|平日のPV数|
|td_area_capital|首都（東京）からのPV数|
|td_area_other|首都（東京）以外からのPV数|
|td_device_sp|スマホからのPV数|
|td_device_pc|パソコンからのPV数|
|td_ref_app|アプリからの流入数|
|td_ref_sosial|SNSからの流入数|
|td_ref_ad|広告からの流入数|
|td_ref_organic|オーガニック検索からの流入数|
|td_ref_email|EMAILからの流入数|
|td_ref_karte|KARTEからの流入数|
|td_ref_other|その他からの流入数|
|td_channel_google|Googleからの流入数|
|td_channel_criteo|Criteoからの流入数|
|td_channel_yahoo|Yahooからの流入数|
|td_channel_line|LINEからの流入数|
|td_channel_facebook|Facebookからの流入数|
|td_channel_instagram|Instagramからの流入数|
|td_channel_tiktok|TikTokからの流入数|
|td_channel_other|その他からの流入数|
|td_pv_ss|春夏のPV数|
|td_pv_aw|秋冬のPV数|
|td_pv_sale|セール期間のPV数|
|td_pv_proper|定価販売期間のPV数|
|td_recency|最終アクセス　リーセンシー|
|td_frequency|サイト訪問の日数|
|td_volume|ユニークなページ閲覧数|
|td_engagement_score|エンゲージメントスコア|
|td_engagement_score_decile|エンゲージメントスコアの10段階ランク|

