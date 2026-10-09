-- 【BigQueryコンソールで実行】パーティション分割テーブルの日/月ごとのサイズ確認
-- 分割単位（日 or 月）を決めるために使う。1分割あたり 7GB 以下を目安にする
SELECT
  SUBSTR(partition_id, 1, 6) AS partition_month  -- 日単位で見る場合は partition_id のまま
  , SUM(total_rows) AS total_rows
  , ROUND(SUM(total_logical_bytes) / POW(1024, 3), 2) AS logical_gb
FROM `PROJECT_ID.BQ_DATASET`.INFORMATION_SCHEMA.PARTITIONS
WHERE table_name = 'BQ_TABLE'
  AND partition_id NOT IN ('__NULL__', '__UNPARTITIONED__')
GROUP BY 1
ORDER BY 1
