# TD ROI Analytics

Treasure DataでのROI分析ワークフロー。ECサイトのWebログとPOSデータを組み合わせて、直接コンバージョンのROI分析を実行します。

## 概要

このワークフローは以下の処理を行います：

1. Webログからコンバージョンセッションを抽出
2. ページビューデータの前処理
3. 注文データとの結合・集計
4. ROI分析結果をGoogle Sheetsに出力

## ファイル構成

```
td_roi_analytics/
├── td_roi_analytics.dig          # メインのDigdagワークフロー
├── config/
│   └── params.yml               # 設定パラメータ
└── queries/
    ├── cv_session.sql           # コンバージョンセッション抽出
    ├── tmp_pv.sql              # ページビュー一時テーブル
    ├── order_pv.sql            # 注文PV処理
    ├── order_pv_non.sql        # 非注文PV処理
    ├── dist_order_pv.sql       # 注文PV分散処理
    ├── td_roi_order_analytics.sql # ROI分析メインクエリ
    └── output.sql              # 出力用クエリ
```

## 設定

### config/params.yml の設定項目

#### Webログ設定
- `weblog_db`: WebログのDB名
- `weblog_tbl`: Webログのテーブル名
- `td_url_col`: URL列名
- `target_session_id`: セッションID列名
- `user_id`: ユーザーID列名
- `web_order_id`: 注文ID列名
- `conversion_urls`: コンバージョンURL（配列）
- `td_flag_params`: TD フラグパラメータ

#### POSデータ設定
- `pos_db`: POSデータのDB名
- `pos_tbl`: POSデータのテーブル名
- `pos_order_id`: POSの注文ID列名
- `amount_col`: 金額列名

### 出力設定
- Google Sheetsへの出力設定をワークフロー内で指定
- `result_connection`: Google Sheetsコネクタ名
- `spreadsheet_folder`: Google Driveフォルダキー
- `spreadsheet_title`: スプレッドシートタイトル

## 実行方法

1. 設定ファイルを環境に合わせて更新
2. Digdagでワークフローを実行

```bash
dig run td_roi_analytics.dig
```

## 処理フロー

1. **テーブル作成・初期化**: 必要なテーブルの作成とデータ削除
2. **コンバージョンセッション抽出**: Webログからコンバージョンに至ったセッションを特定
3. **ページビューデータ準備**: 一時テーブルでPVデータを整理
4. **注文データ処理**: コンバージョンありとなしのPVデータを処理
5. **分散処理**: 注文PVデータを分散テーブルに格納
6. **ROI分析**: WebログとPOSデータを結合してROI計算
7. **結果出力**: Google Sheetsに結果を出力

## 出力データ

分析結果には以下の情報が含まれます：
- ファーストタッチアトリビューション（ソース、メディア、キャンペーン）
- ラストタッチアトリビューション（ソース、メディア、キャンペーン）
- ユーザーID、注文ID、注文時刻
- 売上金額

## 注意事項

- 過去365日分のデータを分析対象とします
- タイムゾーンはAsia/Tokyoに設定されています
- Google Sheetsへの出力には適切なコネクション設定が必要です