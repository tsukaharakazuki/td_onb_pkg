# Workflowについて
  
このWorkflowはWebアクセス履歴を元に、ユーザーのエンゲージメントスコアを算出するものです。
  
![RFV](https://github.com/tsukaharakazuki/image/blob/master/rfv.png?raw=true "RFV")
  
メディアごとに、細かい集計ロジックの調整は必要になりますが、ベースとなるデータを作成し、チューニングを楽にすることが可能です。
  
# 準備
  
`config/params.yml`にてWF環境におけるデータ定義をする必要があります。

- サンプル
```
td:
  # 結果が出力されるDatabase
  database: td_engagement

# WebLogが格納されているDatabase
weblog_db: td_audience_studio
# WebLogが格納されているTable
weblog_tbl: agg_weblog
# スコアを算出するID（user_id / cookieなど）
key_id: user_id

# スコアを算出する期間設定（現設定だと、ログが格納されている全期間と365日分の2パターンで出力）
config_each:
  - label: ltv
    time_filter: TD_TIME_RANGE(time ,NULL ,TD_TIME_FORMAT(TD_SCHEDULED_TIME(), 'yyyy-MM-dd 00:00:00', 'JST') ,'JST')
    target_date: ${td.last_results.progress}
  - label: 365d
    time_filter: TD_INTERVAL(time,'-365d','JST')
    target_date: 365
```

# エンゲージメントスコアの算出ロジックについて
`queries/main.sql` 内で計算しています。
```
log10(td_frequency * SQRT(td_volume)* (${val.target_date} + td_recency + 2)) AS td_engagement_score
```
`td_recency`は、最終アクセス日から今日の日付を引き算するため、マイナスで値が入ります。しかし、エンゲージメントの計算においては-100(100日前アクセス)よりも、-1(昨日アクセス)の方がスコアを高く計算するロジックにするために、`(${val.target_date} + td_recency + 2)`で計算しています。
