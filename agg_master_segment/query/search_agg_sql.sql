SELECT
  'SELECT td_ms_id ,'|| 
  ARRAY_JOIN(
    ARRAY_AGG(
      'MAX_BY('|| column_name|| ', if('||column_name||' is null,null,time)) AS '|| column_name
    )
    , ','
  )
  || ' FROM '|| table_name|| ' GROUP BY td_ms_id' AS sql_contents
FROM
  information_schema.columns
WHERE
  table_schema = '${media[params].output_db}'
  AND table_name = 'tmp_ms_attribute_pred'
  AND column_name <> 'td_ms_id'
GROUP BY
  table_name
