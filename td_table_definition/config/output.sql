SELECT
  database_name ,
  table_name 
FROM
  td_table_definition
GROUP BY
  1,2
ORDER BY
  1,2