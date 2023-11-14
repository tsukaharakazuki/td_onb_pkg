# Treasure DataのAudience Studioをフル活用いただくためのデータ作成Tips集です

## Attribute/Behavior共通

### Date形式カラムのUnixTimeへの変換
`2023-01-01`のような形でデータが入っているカラムをUnixtimeに変換してください。  
Audience Studioの選択時に、Time Filter形式で選択可能な設定が可能です。  

- SAMPLE SQL  
```
SELECT
  TD_TIME_PURSE(order_date,'JST') AS unix_order_date
```
- SAMPLE OUTPUT
  
| order_date | unix_order_date |
----|---- 
| 1986-11-11 | 532018800 |

#### 注意すべきカラム
|Attribute|
----|
|誕生日|
|会員登録日|
|初回購入日|
|最終購入日|

|Behavior|
----|
|注文日|
|発送日|
|発送予定日|
|アクセス日|
|来店日|

- APIでのTimestamp設定
https://github.com/tsukaharakazuki/td_onb_pkg/tree/main/audience-studio-time-filter


## Attribute Data設定
### Date Diff値カラムの作成
経過日数を取り扱いた日付などは、先にDiffを計算してLong型のカラムを作成しておくと、セグメントの設定が楽になります。
- SAMPLE SQL
```
SELECT
  DATE_DIFF('DAY', CAST(DATE_FORMAT(DATE_PARSE(regist_date), '%Y-%m-%d'),'%Y-%m-%d') as DATE), CAST(TD_TIME_FORMAT(TD_SCHEDULED_TIME(), 'yyyy-MM-dd') as DATE)) AS regist_duration
```
- SAMPLE OUTPUT  
  
| regist_date | regist_duration |
----|---- 
| 1986-11-11 | 3 |

#### 注意すべきカラム
|Attribute|
----|
|会員登録日|
|初回購入日|
|最終購入日|

### 年齢カラムの作成
誕生日の日付データしか持っていない場合は、年齢の計算をしたカラムを作成することをお勧めします  
カラム内のDate型のフォーマットについてはこちらを参考に変更ください  
https://prestodb.io/docs/current/functions/datetime.html#mysql-date-functions  

- SAMPLE SQL
```
SELECT
  DATE_DIFF('YEAR', CAST(DATE_FORMAT(DATE_PARSE(birth_day)), '%Y-%m-%d %H:%i:%s.%f'),'%Y-%m-%d') as DATE), CAST(TD_TIME_FORMAT(TD_SCHEDULED_TIME(), 'yyyy-MM-dd') as DATE)) AS age
```
- SAMPLE OUTPUT  
  
| birth_day | age |
----|---- 
| 1986-11-11 00:00:00.000 | 37 |

### 登録した日に初回購入してそのまま離脱したユーザーカラムと経過日数作成
ECでのデータ活用において、よく会員登録日と最終購入日カラムをユーザーごとに生成するところまでは処理できていますが、そこから一歩踏み込み、フラグ化し、経過日数とともにデータを持つことで、施策の幅が広がります。  
F2転換施策をやりたいという要望は多くありますが、初回購入からの経過日数に応じて実施すべき施策は別であるべきだと考えます。  

- SAMPLE SQL
```
SELECT
  regist_date ,
  last_order_date ,
  CASE
    WHEN 
      TD_TIME_FORMAT(TD_TIME_PARSE(regist_date,'JST'),'yyyy-MM-dd') = TD_TIME_FORMAT(TD_TIME_PARSE(last_order_date,'JST'),'yyyy-MM-dd')
    THEN 
      1
    ELSE 
      0
  END onetime_flag ,
  DATE_DIFF('DAY', CAST(DATE_FORMAT(DATE_PARSE(last_order_date, '%Y-%m-%d'),'%Y-%m-%d') as DATE), CAST(TD_TIME_FORMAT(TD_SCHEDULED_TIME(), 'yyyy-MM-dd') as DATE)) AS duration_days
```
- SAMPLE OUTPUT  
  
| regist_date | last_order_date | onetime_flag | duration_days |
----|----|----|----
| 1986-11-11 | 1986-11-11 | 1 | 4 |


### 誕生日カラムの分解
Date形式で入っているカラムを分解することで、特定日付のユーザーだけを抽出するなどのセグメント作成が楽になります。  
Ex)11月誕生日のユーザーだけを抽出したい場合  
`birth_month = 11`

- SAMPLE SQL
```
SELECT
  birth_day ,
  TD_TIME_FORMAT(TD_TIME_PARSE(birth_day,'JST'),'yyyy') AS birth_year ,
  TD_TIME_FORMAT(TD_TIME_PARSE(birth_day,'JST'),'MM') AS birth_month ,
  TD_TIME_FORMAT(TD_TIME_PARSE(birth_day,'JST'),'dd') AS birth_date 
```
- SAMPLE OUTPUT  
  
| birth_day | birth_year | birth_month | birth_date |
----|----|----|----
| 1986-11-11 | 1986 | 11 | 11 |


### 誕生日フラグ作成
翌日誕生日のユーザーにメールを送りたい、来週誕生日のユーザーに誕生日まで有効な特別クーポンの案内を広告で配信したいなど施策を実行する場合、先にカラムを生成していく必要があります。

- SAMPLE SQL
```
SELECT
  birth_day ,
  CASE
    WHEN TD_TIME_FORMAT(TD_TIME_PARSE(birth_day,'JST'),'MM-dd') = TD_TIME_FORMAT(TD_SCHEDULED_TIME(),'MM-dd') THEN 'Today'
    WHEN TD_TIME_FORMAT(TD_TIME_PARSE(birth_day,'JST'),'MM-dd') = TD_TIME_FORMAT(TD_TIME_ADD(TD_SCHEDULED_TIME(),'1d','JST'),'MM-dd') THEN 'Tomorrow'
    WHEN TD_TIME_FORMAT(TD_TIME_PARSE(birth_day,'JST'),'MM-dd') = TD_TIME_FORMAT(TD_TIME_ADD(TD_SCHEDULED_TIME(),'7d','JST'),'MM-dd') THEN 'Next Week'
    WHEN TD_TIME_FORMAT(TD_TIME_PARSE(birth_day,'JST'),'MM-dd') = TD_TIME_FORMAT(TD_TIME_ADD(TD_SCHEDULED_TIME(),'30d','JST'),'MM-dd') THEN 'Next Month'
    ELSE NULL
  END birth_day_flag 
```
- SAMPLE OUTPUT  
  
| birth_day | birth_day_flag |
----|----
| 1986-11-11 | Today |


### 電話番号やEMAILのアグリゲート
LINEにセグメント連携する場合は`+818011112222`の形式でデータ連携する必要があるなど、プラットフォームにより特に電話番号は出力形式が異なります。事前に連携するプラットフォームの型に合わせて整形しておくことが必要です。

- SAMPLE SQL
```
SELECT
  phone ,
  SUBSTR(phone,2) AS phone_remove0 ,
  '+81'||SUBSTR(phone,2) AS phone_remove0plus81 ,
  LOWER(TO_HEX(SHA256(TO_UTF8(phone)))) AS phone_hash ,
  LOWER(TO_HEX(SHA256(TO_UTF8(SUBSTR(phone,2))))) AS phone_hash_remove0 ,
  LOWER(TO_HEX(SHA256(TO_UTF8('+81'||SUBSTR(phone,2))))) AS phone_hash_remove0plus81 ,
  email ,
  LOWER(TO_HEX(SHA256(TO_UTF8(email)))) AS email_hash ,
  'JP' AS country_code
```
- SAMPLE OUTPUT  
  
| phone | phone_remove0 | phone_remove0plus81 | phone_hash | phone_hash_remove0 | phone_hash_remove0plus81 | email | email_hash | country_code |
----|----|----|----|----|----|----|----|----
| 08011112222 | 8011112222 | +818011112222 | AAAAAAAAAA | BBBBBBBBBB | CCCCCCCCCC | aaa@aaa.com | DDDDDDDDDD | JP |


## Behavior Data設定

### timeカラムにはアクセス日や注文日のUnixtimeを入れる
td-js-sdkで取得しているWebアクセスログなどのtimeカラムにはデータが取得された値が入っていますが、購買データなど外部DBから取り込まれたデータについては取り込み日が入力されている場合が多く見られます。  
セグメント作成後のProfileサンプルのビヘイビアデータはtimeカラム順に表示されますので、きちんと時系列に並べたい値を入れておくことで、N1分析の用途でも利用可能です。

### td_urlカラムの生成
セグメント作成後のProfileサンプルのビヘイビアデータは,`td_url`カラム内に入力されている値が表示されます。  
購買データなどをBihabiorテーブルに設定する場合、ベースになるデータに`td_url`カラムを追加して、表示したい値を入力してあげることで、Audience Studioの視認性が大幅にアップします。  

- SAMPLE SQL
```
SELECT
  sku ,
  price ,
  '購買ログ 商品:'||IF(sku is NULL,'',sku)||' 金額:'||IF(price is NULL,'',price)  AS td_url
```
- SAMPLE OUTPUT  
  
| sku | price | td_url |
----|----|----
| Tシャツ | 3000 | 購買ログ 商品:Tシャツ  金額:3000 |
