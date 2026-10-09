-- 【BigQueryコンソールで実行】データセット内テーブルのサイズ確認
-- region-us は対象データセットのロケーションに合わせて変更（例: region-asia-northeast1）
-- total_logical_bytes は全カラム分。SELECTするカラムを絞ると実際の読み込み量はこれより小さくなる
SELECT
  table_schema
  , table_name
  , total_rows
  , ROUND(total_logical_bytes / POW(1024, 3), 2) AS logical_gb
  , CASE
      WHEN total_logical_bytes / POW(1024, 3) < 7 THEN 'full_import / incremental_import'
      ELSE 'split_import（分割キーの設計が必要）'
    END AS recommended_mode
FROM `PROJECT_ID.region-us`.INFORMATION_SCHEMA.TABLE_STORAGE
WHERE table_schema = 'BQ_DATASET'
ORDER BY total_logical_bytes DESC
