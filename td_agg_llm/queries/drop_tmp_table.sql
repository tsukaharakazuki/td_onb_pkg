SELECT
  table_name 
FROM
  information_schema.columns
WHERE
  table_schema = '${td.database}'
  AND NOT REGEXP_LIKE(table_name,'^enriched_') 
GROUP BY
  1