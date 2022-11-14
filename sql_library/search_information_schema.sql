SELECT
  column_name
FROM
  information_schema.columns
WHERE
  table_schema = 'DATABASE_NAME'
  AND table_name = 'TABLE_NAME'