# はじめに
このWorkflowは、Database内のTableを参照し、サンプルデータと共にGoogleスプレッドシートに定義ファイルを出力するものです

# 設定
`config/params.yml` ファイルで設定をします。  
  
```
# データが出力されるTable
td:
  database: td_audience_studio
```
TD内に一度出力前のデータを作成するので、作成データを保存するDatabaseを指定してください  
  

```
# 定義書を作成したいDatabase
db_list:
  - td_audience_studio
```
テーブル定義書を作成したいTableが入っているDatabaseを指定  
  

```
columns:
  - time
  - td_charset
  ...
```
全てのDatabaseを共通でカラム定義されているカラムを指定  
*基本的には変更しない*
  

```
data_types:
  - array(varchar)
  - bigint
  - double
  - varchar

flags:
  - common
  - specific
```
定義ファイルなので変更不要 
  
```
googlesheet:
  result_connection: CONNECTOR_NAME
  spreadsheet_folder: FOLDER_ID
```
出力するGoogle Sheetのコネクタ名と、出力したいフォルダのIDを入力してください
  