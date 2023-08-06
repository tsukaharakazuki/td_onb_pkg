SELECT
  database_name AS "データベース名" ,
  table_name AS "テーブル名"  ,
  ordinal_position AS "カラム順" ,
  column_name AS "カラム名"  ,
  data_type AS "データ型"  ,
  sample AS "サンプルデータ"  
  --, '' AS  "説明"  
FROM
  table_difinition
WHERE
  database_name = '${td.each.database_name}'
  AND table_name = '${td.each.table_name}'
ORDER BY
  ordinal_position ASC
