SELECT 
  database_name
  ,table_name
FROM
  tmp_columns_${flag}_${data_type.col}
GROUP BY 
  1,2
