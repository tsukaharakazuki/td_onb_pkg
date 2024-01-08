WITH target_schema AS (
  SELECT
    database_name ,
    table_name ,
    column_name ,
    ROW_NUMBER() OVER (PARTITION BY column_name) AS num
  FROM
    tmp_information_schema
  WHERE
    data_type = '${data_type.dt}'
    AND regexp_like(
      column_name,
      '^(${(Object.prototype.toString.call(columns) === '[object Array]')?columns.join('|'):''})$'
    )
  GROUP BY
    1,2,3
)

SELECT
  database_name ,
  table_name ,
  column_name 
FROM
  target_schema
WHERE
  num = 1
