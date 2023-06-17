SELECT
  '${td.each.database_name}' AS db_name ,
  '${td.each.table_name}' AS tbl_name ,
  '${td.each.column_name}' AS col_name ,
  CAST(${td.each.column_name} AS varchar) AS sample
FROM
  ${td.each.database_name}.${td.each.table_name}
WHERE
  ${td.each.column_name} is not NULL
LIMIT 1