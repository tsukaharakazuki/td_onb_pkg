-- 出力テーブル（findings / notifications / activity）が作成済みかを確認します
-- 3 未満なら sub_ensure_setup.dig が sub_setup.dig を実行します
SELECT
  COUNT(1) AS table_count
FROM
  information_schema.tables
WHERE
  table_schema = '${output_db}'
  AND table_name IN (
    '${findings_table}${table_suffix}',
    '${notifications_table}${table_suffix}',
    '${activity_table}${table_suffix}'
  )
