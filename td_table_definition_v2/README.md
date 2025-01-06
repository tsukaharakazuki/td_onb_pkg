# このWorkflowについて
このWorkflowはTD内のテーブルから、サンプルデータを含めたテーブル定義書のベースとなるデータを作成するWorkflowです。  
このサンプルでは、Googleスプレッドシートのコネクタを利用して、任意のGoogleDriveフォルダ内にデータを出力します。  
変更したい場合は書き換えてください。

# 設定
`params.yml`ファイルを書き換えてください。  
```
td:
  database: OUTPUT_DATABASE

* OUTPUT_DATABASE
中間テーブルを一時的に作成するDatabaseを指定してください。

target:
  target1:
    db: TARGET_DATABASE
    tbl:
      - TARGET_TABLE1
      - TARGET_TABLE2
      - TARGET_TABLE3

* target
出力したいテーブルを、データベースごとに設定していきます。
スプレッドシートへの出力もデータベースごとに分けて出力されます。
複数のデータベースをまたいで一回で出力設定することが可能です。


googlesheet:
  result_connection: CONNECTOR_NAME
  spreadsheet_folder: GDRIVE_FOLDER_ID
  sheetname: TD_テーブル定義書

* googlesheet
スプレッドシートに出力する設定です。
CONNECTOR_NAME 作成されているAuthenticationの名前を入力してください。
GDRIVE_FOLDER_ID 出力したいGoogle DriveのフォルダURLから、フォルダIDをコピーして入力してください。
```
