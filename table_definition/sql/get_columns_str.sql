SELECT
  ARRAY_JOIN(array_sort(array_distinct(ARRAY_AGG('''' || column_name || ''''))), ',') AS col_name_columns
  ,ARRAY_JOIN(array_sort(array_distinct(ARRAY_AGG(column_name))), ',') AS sample_columns
  ,ARRAY_JOIN(array_sort(array_distinct(ARRAY_AGG('MAX(' || column_name || ') AS ' || column_name))), ', ') AS max_col_name_columns
FROM
  tmp_columns_${flag}_${data_type}
WHERE
  database_name = '${td.each.database_name}'
  AND table_name = '${td.each.table_name}'