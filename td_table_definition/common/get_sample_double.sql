WITH t0 AS (
  SELECT
    database_name ,
    table_name ,
    column_name ,
    ROW_NUMBER() OVER (PARTITION BY column_name) AS num
  FROM
    tmp_information_schema
  WHERE
    data_type = 'double'
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
  t0
WHERE
  num = 1