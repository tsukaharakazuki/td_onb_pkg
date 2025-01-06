WITH tmp AS (
  SELECT
    a.database_name ,
    a.table_name ,
    a.ordinal_position ,
    a.column_name ,
    a.data_type ,
    b.sample ,
    b.col_info
  FROM
    td_table_definition a
  LEFT JOIN 
    td_table_definition_sample b
  ON
    a.column_name = b.col_name
  WHERE
    a.database_name = '${td.each.database_name}'
    AND a.table_name = '${td.each.table_name}'
)

, dist AS (
  SELECT
    a.database_name ,
    a.table_name ,
    a.ordinal_position ,
    a.column_name ,
    a.data_type ,
    IF(a.sample is NULL,b.value,a.sample) AS sample ,
    a.col_info 
  FROM
    tmp a
  LEFT JOIN
    td_sample_unpivot_data b
  ON
    a.column_name = b.key
)

SELECT
  database_name AS "データベース名" ,
  table_name AS "テーブル名"  ,
  ordinal_position AS "カラム順" ,
  column_name AS "カラム名"  ,
  data_type AS "データ型"  ,
  sample AS "サンプルデータ" ,
  col_info AS  "説明"  
FROM
  dist
ORDER BY
  ordinal_position ASC