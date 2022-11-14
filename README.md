# はじめに
TreasureDataの初期構築において活用できるWorkflowパッケージです。

# 準備(Treasure Data Toolbelt: Command-line Interfaceのダウンロード)
  
WorkflowファイルをTreasureData環境にインストールするためには、Treasure Data Toolbelt（CLI）の利用が必要です。以下からダウンロードしてインストールしてください。  
 - ドキュメント
 https://support.treasuredata.com/hc/en-us/articles/360000720048-Treasure-Data-Toolbelt-Command-line-Interface
 
 - Toolbeltダウンロードリンク
 https://toolbelt.treasuredata.com/

# CLIコマンド
## TDアカウントへのログイン
### USリージョン
`td account -f`
### Tokyoリージョン
`td -e https://api.treasuredata.co.jp account -f`
### SSOログインの場合
1. 事前のログイン情報を削除`rm ~/.td/td.conf`
2. API KEYのセット`td apikey:set YOUR_API_KEY`
### Tokyoリージョンにログインした状態からUSリージョン環境にログイン
`td -e https://api.treasuredata.com account -f`

## チェンジディレクトリ
アップロードするフォルダに移動する必要があります。 
  
`cd AAAA/BBBB`　　

Macの場合、Userの状態からダウンロードフォルダへの移動は
  
`cd downloads`
  
コマンドで移動します

## Workflowファイルのアップロード
  
コマンドを実行する前にcdコマンドでアップロードしたいWFファイルが存在するフォルダに移動
  
`td wf push set_project_name`
