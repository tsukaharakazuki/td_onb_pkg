SELECT 
  table_schema AS database_name ,
  table_name ,
  column_name ,
  data_type ,
  ordinal_position 
FROM
  information_schema.columns
WHERE
  regexp_like(
    table_schema,
    '^(${(Object.prototype.toString.call(db_list) === '[object Array]')?db_list.join('|'):''})$'
  )