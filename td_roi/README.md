# はじめに
このWorkflowはtd-js-sdkで取得しているWebログ、購買データがTDに入っている場合、流入もとごとのROIを計算するためのテンプレートです。

# 必要なデータ
###　Webログ
JSで取得しているデータに対して、セッションIDの生成、セッション番号の生成が必要です。  
その上で、セッションの途中でログインした際の会員IDの補完処理を事前におこなてください。  

こちらのテンプレを使用いただくと簡単です。  
https://github.com/tsukaharakazuki/td_onb_pkg/tree/main/agg_weblog

###　POSデータ
キャンセルログなどがPOSに入っている場合は事前に削除いただくなど、正確に計測したいデータだけを前処理してください。

# パラメータ設定
`config/params.yml`  
上記ファイルで設定します。  
```
td:
  database: td_sandbox ->出力結果が保存されるDB

roi_judge_date: 7 ->購入日から遡って流入元を計測する日数

# Webログ設定
web:
  db: WEB_LOG_DB
  tbl: WEB_LOG_TBL
  time_col: time
  user_id: user_id_comp
  utm_source: td_source
  utm_medium: td_medium
  utm_campaign: utm_campaign
  where_condition:
    #- session_num = 1

# 購買ログ設定
pos:
  db: POS_LOG_DB
  tbl: POS_LOG_TBL
  time_col: TD_TIME_PARSE(TD_TIME_FORMAT(time, 'yyyy-MM-dd 23:59:59','JST'),'JST') #購入日がyyyy-MM-ddで入っている場合は、23:59:59を追加した方が良い
  user_id: user_id
  amount_col: AMOUNT_COL
  add_cols:
    #- カラムが追加になる場合以下に追記
    #- order_id
    #- brand
    #- itemcd
    #- product_id
    #- product_name 
  where_condition:
   # - product_name not RLIKE '無料'

# 結果出力設定
result_type: googlesheet
result_google:
  result_1:
    connecter: GOOGLESHEET_CONNECTER_NAME
    folder: GOOGLESHEET_FOLDER_ID
```