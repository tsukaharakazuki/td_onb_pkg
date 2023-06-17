SELECT
  '${td.each.database_name}' AS db_name ,
  '${td.each.table_name}' AS tbl_name ,
  '${td.each.column_name}' AS col_name ,
  ARRAY_JOIN(${td.each.column_name},',') AS sample
FROM
  ${td.each.database_name}.${td.each.table_name}
WHERE
  ${td.each.column_name} is not NULL
  AND ${td.each.column_name} <> ''
LIMIT 1