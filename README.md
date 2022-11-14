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

# td_onb_pkg内の各Workflowについて
## agg_weblog
`td-js-sdk`で取得したデータを使いやすく加工する処理です。  
この他の全てのWorkflowで使われるベースとなる処理ですので、一番初めに実行してください
## agg_master_segment
マスターセグメントを構築する3つのコアテーブル（Master table/behavior/attribute）を作成する処理です。  
初回実行後マスターセグメントが作成されたら、`master_segment_id`を設定ファイルに入力することで、定期更新されます。
## ml_lookalike
TD内で作成した教師データをもとに、機械学習でスコアリングを実施します。  
教師データは、Workflow内のSQLで作成する、もしくは、Audience Studioで作成し、TD内のTableに描き戻す、どちらかで作成することが可能です、
## ml_gender_age
年齢・性別の機械学習推計処理。教師データとなるユーザーデータ（年齢・性別）が行動ログと紐づく形でTD内に格納されている場合実行可能です。
## article_report
メディア企業・EC企業などで活用いただける処理です。個別のページURLや、カテゴリがURLディレクトリで分かれている場合、そのデータをBI用に作成します。
## workflow_training
Workflowについて学んでいただくコンテンツです。
