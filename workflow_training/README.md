### Workflowサンプルテンプレート　
https://github.com/tsukaharakazuki/td/blob/master/workflow_template/template.dig

# timezone
処理実行されるタイムゾーンを設定
スケジュールの実行時間などをどのタイムゾーンで実行するかに影響
```
timezone: "Asia/Tokyo"
```

# `schedule:`スケジュール設定
http://docs.digdag.io/scheduling_workflow.html?highlight=schedule
```
schedule:
  cron>: 1 3 1,10,20 1,2,3 0
  OR
  daily>: 03:00:00 #日時バッジ
  else...
``` 
cronについて  
https://docs.treasuredata.com/display/public/PD/Cron+Schedule+Values

#  `_export:`での変数設定
https://docs.digdag.io/workflow_definition.html#using-export-parameter
```
_export:
  !include : 'config/params.yml'
  td:
    database: td_sandbox #ベースの参照・出力先Database
```

# `_error:`エラー通知設定
Workflowの途中でエラーになった場合、`_error:` で記述したタスクが実行されます  
サンプルでは`config/error.dig`が実行されます  
サンプルではメールでの通知ですが、Slack、Teams、Chatworkなどチャットツールなどに通知することも可能です
```
_error:
  +error_mail:
    call>: config/error.dig
```

# task基本形
```
+task_template:
  td>: queries/presto.sql
  create_table: test_ec
```
```
+タスク名:
  オペレーター>: 実行ファイル
  出力設定: 出力先データベース.テーブル名
```
タスク名`task_template:`は同一インデントでユニーク

オペレータードキュメント  
http://docs.digdag.io/operators.html

# 処理記述例
## `td>:` Workflow内に存在するsqlファイルを実行
```
+sql:
  td>: queries/sample_query.sql
  create_table: test_ec #(存在するテーブルを削除して作り直す)
  #insert_into: test_ec #(存在するテーブルに追記で書き込み)
```

## `td>:` _exportで定義した変数を読み込んで処理実行
```
+sql_variable:
  td>: queries/sample_query_variable.sql
  create_table: ${result_table}
```

## `td>:` Hiveでの処理実行
```
+sql_hive:
  td>: queries/sample_query_hive.sql
  insert_into: ${hive.result_table}
  engine: hive 
  engine_version: stable #Tez
```
WITH区を含むSQLの場合、INSERT区を挿入する場所に`-- DIGDAG_INSERT_LINE`を記載


## `td_ddl>:` tableの作成やdropなどの処理実行  
https://docs.digdag.io/operators/td_ddl.html

### `create_tables` tableが存在しない場合は作成、存在する場合はそのまま
```
+create_tables:
  td_ddl>:
  create_tables: 
    - "my_table_${session_date_compact}"
```
### `drop_tables` tableの削除
```
+drop_tables:
  td_ddl>:
  drop_tables: 
    - "my_table_${session_date_compact}"
```
### `empty_tables` tableが存在しない場合は作成、存在する場合は削除してから再作成
```
+empty_tables:
  td_ddl>:
  empty_tables: 
    - "my_table_${session_date_compact}"
```
### `rename_tables` table名の変更
```
+rename_tables:
  td_ddl>:
  rename_tables: 
    - {from: "my_table_${session_date_compact}", to: "my_table"}
```

## `${session_date}`など予約変数
https://docs.digdag.io/workflow_definition.html#using-variables  
Workflowには`${session_date}`->`2023-01-01`  
*Workflowが実行された日付が代入される  
など、予約された変数が存在します。s3にデータを出力する際に日付prefixを末尾につける場合などにも使用


## `moment.js`での日付処理  
https://docs.digdag.io/workflow_definition.html?highlight=moment%20js#calculating-variables  
https://momentjs.com/  
ex.   
`${moment(session_time).add(1, 'days').format("YYYYMMDD")}`  
たとえば`2022/1/1`にWorkflow実行された場合、`20220102`が出力されます  
ファイル名に前日日付を記載したい場合などに使用


## `if>:` 処理分岐
```
+if:
  if>: true #true or false
  _do:
    +if_true:
      td_ddl>:
      empty_tables: 
        - "if_table_true"
  _else_do:
    +if_false:
      td_ddl>:
      empty_tables: 
        - "if_table_false"
```
`_do:` trueの際に処理実行  
`_else_do:` falseの際に処理実行  

#### `if>:`での判定処理記述例
`${if_type == 'treasure'}`  
変数`if_type`で設定したテキストが同じだった場合`true`

`${(Object.prototype.toString.call(if_val) === '[object Array]')}`  
変数`if_val`が配列だった場合`true`

`${moment().format('dddd') === dow} `  
変数`dow`で設定した曜日と実行日が同じだった場合`true`


## `for_each>:` 変数設定を変更して複数回同一処理実行
```
+for_each:
  for_each>:
    val: 
      - start: 2022-01-01
        end: 2022-02-01
        tbl: 2201_2202
      - start: 2022-02-01
        end: 2022-03-01
        tbl: 2202_2203
  _do:
    +proc_for_each:
      td>: queries/sample_query_for_each.sql
      create_table: result_${val.tbl}
```
```
+for_each_param:
  for_each>:
    val: ${for_each_param}
  _do:
    +proc_for_each:
      td>: queries/sample_query_for_each.sql
      create_table: result_${val.tbl}
```

## `loop>:` Loopでの処理実行
```
+loop:
  loop>: 10
  _do:
    +proc_loop:
      td>: 
      query: SELECT '${i + 1}' AS col_${i + 1}
      insert_into: loop_table
```
`loop>: 10` この場合後続処理を`10回`繰り返します  
`${i}`がloop回数で変動する変数になります  
`${i}`は`0`から始まるので、上記サンプルでは`${i + 1}`として`1`からスタートするようにしています


## `call>:`/`require>:` 別のdigファイル呼び出し
https://plazma.red/user_engagement/howto/0107
```
+call_other_dig:
  call>: other.dig
```
`call>:`は同じProject内に存在するdigファイルを実行  
親digのタスクにネストされる形で処理実行される

```
+require_other_dig:
  require>: other
  project_name: PROJECT_NAME
```
`require>:`は異なるProjectのdigファイルも実行可能  
`require`されたdigは別のタスクとして処理実行される  
Workflowではdig内のタスクが1000タスクを超えるとエラーになってしまうため、`for_each` `loop`などで多くの処理を実行しなければならない場合などは、digを小分けにして`require`するといった利用も可能
  
## `td_for_each>:` SQLでeach処理の変数取得  
https://docs.digdag.io/operators/td_for_each.html
```
+td_for_each:
  td_for_each>: queries/search_td_for_each_params.sql
  _do:
    +proc:
      td>: 
      query: SELECT '${td.each.key}' AS key , ${td.each.val} AS val FROM ${td.each.tbl}
      create_table: result_${td.each.name}
```
`queries/search_td_for_each_params.sql`で出力された値を変数にしてeach処理の実行が可能  
後続処理では、`${td.each.○○○○}`でカラム名を指定し、変数の呼び出し

## `store_last_results`での変数引き継ぎ  
https://plazma.red/user_engagement/howto/0317
```
+store_last_results:
  td>: 
  query: SELECT COUNT(*) AS check AS target_tbl
store_last_results: true

+if:
  if>: ${td.last_results.check} > 0
  _do:
    +results_outpt:
      td>: 
      query: SELECT key , val FROM target_tbl
```
`store_last_results: true`で処理されたSQLの値を後続の処理で変数として使用  
後続処理では、`${td.last_results.○○○○}`でカラム名を指定し、変数の呼び出し

## コネクタでのデータアウトプット
Google Sheet出力サンプル
```
+result_google_sheets:
  td>: 
  query: SELECT * FROM google_sheet_table
  result_connection: YOUR_GOOGLE_SHEETS_CONNECTER_NAME
  result_settings:
    spreadsheet_folder: YOUR_GOOGLE_DRIVE_FOLDER_KEY
    spreadsheet_title: "ファイル名"
    sheet_title: "シート1"
    mode: truncate
```

## `py>:` Custom Script(Python operator)
WorkflowではDockerを立ち上げPython Scriptを実行することが可能です  
機械学習、APIを叩いて他ツールからデータを取り込む、SQLでは処理できないデータ処理などを実行することができます  
https://docs.treasuredata.com/display/public/PD/Introduction+to+Custom+Scripts  
https://plazma.red/user_engagement/howto/0108  
```
+python:
  docker:
    image: "digdag/digdag-python:3.9"
  _env:
    TD_API_KEY: ${secret:td.apikey}
    ENDPOINT: ${td.endpoint}
    SESSION_UNIXTIME: ${session_unixtime}
  py>: pyscript.train_predict.main
  database: ${td.database}
  timezone: ${timezone}
  tbl_name: ${py_tbl}
  train: train_${py_name}
  preprocessed: preprocessed_${py_name}
  predicted: predicted_${py_name}
  n_features: 1000
  n_split: 10
```
