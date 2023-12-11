SELECT
  database_name ,
  table_name ,
  column_name
FROM
  tmp_information_schema
WHERE
  data_type = '${data_type}'
  AND NOT regexp_like(
    column_name,
    '^(${(Object.prototype.toString.call(columns) === '[object Array]')?columns.join('|'):''})$'
  )
GROUP BY
  1,2,3