WITH t0 AS (
  SELECT
    a.* ,
    b.sample
  FROM
    tmp_information_schema a
  LEFT JOIN
    tmp_table_definition_sample_common b
  ON
    a.column_name = b.col_name
)

SELECT
  a.database_name ,
  a.table_name ,
  a.column_name ,
  a.data_type ,
  a.ordinal_position ,
  IF(a.sample is not NULL,a.sample,b.sample) AS sample
FROM
  t0 a
LEFT JOIN
  tmp_table_definition_sample_specific b
ON
  a.database_name = b.db_name
  AND a.table_name = b.tbl_name
  AND a.column_name = b.col_name
