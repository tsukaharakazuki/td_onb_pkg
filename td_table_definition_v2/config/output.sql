SELECT
  database_name ,
  table_name
FROM  
  td_table_definition
GROUP BY
  database_name ,
  table_name