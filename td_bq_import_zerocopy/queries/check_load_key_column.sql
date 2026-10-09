SELECT
  COUNT(1) AS cnt
FROM information_schema.columns
WHERE table_schema = '${dp.td_database}'
  AND table_name = '${target_table}'
  AND column_name = 'td_load_key'
