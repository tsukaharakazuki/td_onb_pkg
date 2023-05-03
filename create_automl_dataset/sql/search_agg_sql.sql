SELECT
  'SELECT user_id ,'|| 
  ARRAY_JOIN(
    ARRAY_AGG(
      'MAX_BY('|| column_name|| ', if('||column_name||' is null,null,time)) AS '|| column_name
    )
    , ','
  )
  || ' FROM '|| table_name|| ' GROUP BY user_id' AS sql_contents
FROM
  information_schema.columns
WHERE
  table_schema = '${database}'
  AND table_name = '${search_tbl}'
  AND column_name <> 'user_id'
GROUP BY
  table_name