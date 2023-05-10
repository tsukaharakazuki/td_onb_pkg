WITH t0 AS (
  SELECT
    table_schema AS db , 
    table_name AS tbl ,
    REGEXP_REPLACE(table_name,'^predicted_','') AS segment_tbl
  FROM
    information_schema.tables
  WHERE
    table_schema = '${database}'
    AND REGEXP_LIKE(table_name,'^predicted_')
)

SELECT
  a.* ,
  b.segment_name
FROM
  t0 a
  INNER JOIN (
    SELECT
      segment_tbl ,
      MAX_BY(segment_name,time) AS segment_name
    FROM
      ${cdp[params].db}.${cdp[params].tbl}
    GROUP BY
      1
  ) b
  ON
    a.segment_tbl = b.segment_tbl
