# Workflowについて
このWorkflowはs3からTDにデータを取り込む際のWF記述テンプレートです。

# ドキュメント
## s3 Import Docs
https://docs.treasuredata.com/articles/#!int/amazon-s3-import-integration-v2/q/s3/qid/14002/qp/5

## td_load サンプル
https://github.com/treasure-data/treasure-boxes/tree/master/td_load/s3

## embulk Docs
https://github.com/embulk/embulk-input-s3

## CSV Parser Function
https://docs.treasuredata.com/articles/#!pd/CSV-Parser-Function 

# 利用方法
## 初期設定状態
`yaml/s3_import.yml` で取り込みの設定がされています。
```
in:
  type: s3
  td_authentication_id: ${s3[param].td_authentication_id}
  bucket: ${s3[param].bucket}
  path_prefix: ${s3[param].path_prefix}
  parser:
    charset: ${s3[param].charset}
    newline: ${s3[param].newline}
    type: ${s3[param].type}
    skip_header_lines: ${s3[param].skip_header_lines}
    allow_extra_columns: false
    allow_optional_columns: false
    columns: ${s3[param].columns}
out:
  mode: ${s3[param].mode}
exec: {}
filters:
- type: add_time
  to_column:
    name: time
    type: timestamp
  from_value:
    mode: upload_time
```
  
TDのtimeカラムには、取り込み日時のUNIXTIMEが入る設定になっています。変更する場合は以下の記述を変更ください。
```
- type: add_time
  to_column:
    name: time
    type: timestamp
  from_value:
    mode: upload_time
```
  
カラムが多い・少ない場合の挙動については、初期設定ではSKIP（データを取り込まない）設定になっています。変更する場合は以下を変更ください。詳細については以下を参照ください。  
https://docs.treasuredata.com/articles/#!pd/CSV-Parser-Function
```
allow_extra_columns: false
allow_optional_columns: false
```
  
不正レコードがあった場合取り込みをエラー処理したい場合は、以下のオプションを追加ください。
```
stop_on_invalid_record: true
```

## 取り込みファイル設定
`config/params.yml`で、取り込むファイルの設定を行います。
```
s3:
  sample1:
    td_authentication_id: S3_CONNECTOR_AUTHENTICATION_ID
    td_output_db: TD_IMPORT_DATABASE_NAME
    td_output_tbl: TD_IMPORT_TABLE_NAME
    bucket: S3_BUCKET_NAME
    path_prefix: prefix/path_ #頭の/は記述しない
    charset: UTF-8
    newline: CRLF
    type: csv
    skip_header_lines: 1
    columns:
      - {name: td_col_name_1, type: string}
      - {name: td_col_name_2, type: string}
    mode: replace #append / replace_on_new_data
```
  
`sample1`のディレクトリをコピペで下に追加していっていただくと、複数ファイルの取り込みが可能です。  
`columins`の設定で、TDに取り込むカラム名とデータ型を定義します。基本的には`string`で取り込み、TDでのSQL処理でCASTすることを推奨します。
