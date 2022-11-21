SELECT
  table_schema , -- database 
  table_name , -- table
  column_name , -- column,
  ordinal_position , -- osition
  data_type -- data_type
FROM
  information_schema.columns
WHERE
  table_schema = 'DATABASE_NAME'
  AND table_name = 'TABLE_NAME'
