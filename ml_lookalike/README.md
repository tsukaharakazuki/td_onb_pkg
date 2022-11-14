# はじめに  
このWorkflowは、目的変数として設定した条件（Ex.商品購入、来店）に合わせて、WebログやAppログ、その他行動ログから機械学習でスコアリングをするWorkflowです。  
機械学習のロジックは`RandomForestClassifier`になります。  
手軽に機械学習を実装することを目的に作成されており、基本的に変更する部分は、`config/params.yml`のみで結果が出力されます。
  
# 変数設定  
`config/params.yml`の各変数を変更します。
  
1. for_eachオペレータ用のKeyのためここは変更しないでください  
```
set:
```
  
1. 基礎設定  
```
  ec_conv: -> このインデント以下を複製して最下に貼り付けることで、別の結果も出力可能です
    firsttime: true -> 初回実行時：true,定期実行時：false
    name: ec_conv -> table名に出力されるので、英数小文字アンダーバーのみ
    output_db: td_sandbox -> 結果を出力するデータベース名
```
  
1. 目的変数（教師データ）設定  
```
    # 目的変数設定
    target_db: target_db -> 教師データを作成するDatabase
    target_tbl: target_tbl -> 教師データを作成するTable
    target_id: td_ms_id -> KeyとなるID（cookie,MobileID,UserIDなど）
    target_time_range: TD_INTERVAL(time, '-28d', 'JST') -> 教師データとなる該当期間
    target_positive: -> 以下は出力条件のWhere区にANDで追加されていきます。`-`で条件式を追加していってください
      condition:
        - td_path = '/ordercomplete'
        - td_path = '/order'
```
  
1. 説明変数設定  
以下の設定で説明変数となるデータを抽出していきます。各変数異なるデータから抽出することができますので、Webの行動ログとAppの行動ログを組み合わせて推計することも可能です。  
```
    # 説明変数設定
    feature_time_range: TD_INTERVAL(time, '-60d', 'JST')
    # 閲覧コンテンツ、リファラなどIDが複数の値を持つカラムの割合計算
    feature_categorical:
      - colmuns: td_path
        id: td_cookie
        db: weblog_db
        tbl: weblog_tbl
        negative_condition: td_path <> '/ordercomplete'
      - colmuns: td_ref_host
        id: td_cookie
        db: weblog_db
        tbl: weblog_tbl
        negative_condition: td_path <> '/ordercomplete'
      - colmuns: TD_TIME_FORMAT(time, 'HH', 'JST')
        id: td_cookie
        db: weblog_db
        tbl: weblog_tbl
        negative_condition: td_path <> '/ordercomplete'
    # 都道府県、OSなどIDが複数の値を持つカラムの最大の値
    feature_max_by_n:
      - colmuns: td_os
        id: td_cookie
        db: weblog_db
        tbl: weblog_tbl
        negative_condition: td_path <> '/ordercomplete'
      - colmuns: prefectures
        id: td_cookie
        db: weblog_db
        tbl: weblog_tbl
        negative_condition: td_path <> '/ordercomplete'
    # 課金額カラムなど数値を合計した値をSUM
    feature_quantitative:
      - colmuns: charge
        id: td_cookie
        db: weblog_db
        tbl: weblog_tbl
        negative_condition: td_path <> '/ordercomplete'
    # 配列カラム内のデータを展開して割合計算
    feature_categorical_array:
      - colmuns: sku
        id: td_cookie
        db: weblog_db
        tbl: weblog_tbl
        negative_condition: td_path <> '/ordercomplete'
    # 配列カラム内のデータを展開して出現回数計算
    feature_categorical_array_cnt:
      - colmuns: order
        id: td_cookie
        db: weblog_db
        tbl: weblog_tbl
        negative_condition: td_path <> '/ordercomplete'
```