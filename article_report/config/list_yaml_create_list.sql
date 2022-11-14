SELECT 
  'SELECT article_id,'|| ARRAY_JOIN(
    ARRAY_AGG(
      'MAX('|| column_name|| ') AS '|| column_name
    ),
    ','
  )|| ' FROM '|| table_name|| ' GROUP BY article_id' AS sql_contents
FROM
  information_schema.columns
WHERE
  table_schema = '${database}'
  AND table_name = 'tmp_list_article_report_base'
  AND column_name <> 'article_id'
GROUP BY
  table_name