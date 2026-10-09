-- 【BigQueryコンソールで実行】非パーティションテーブルの分割キー別サイズ見積もり
-- 1行あたりの平均バイト数 × 分割単位の件数 で読み込み量を見積もる
-- （SELECTするカラムだけで見積もる場合は、bq query --dry_run で処理バイト数も確認できる）
WITH avg_row AS (
  SELECT total_logical_bytes / NULLIF(total_rows, 0) AS avg_row_bytes
  FROM `PROJECT_ID.region-us`.INFORMATION_SCHEMA.TABLE_STORAGE
  WHERE table_schema = 'BQ_DATASET'
    AND table_name = 'BQ_TABLE'
)
SELECT
  DIV(member_id, 5000000) * 5000000 AS split_from  -- 分割キーと刻み幅を変更
  , COUNT(1) AS rows_in_split
  , ROUND(COUNT(1) * ANY_VALUE(avg_row.avg_row_bytes) / POW(1024, 3), 2) AS estimated_gb
FROM `PROJECT_ID.BQ_DATASET.BQ_TABLE`
CROSS JOIN avg_row
GROUP BY 1
ORDER BY 1
