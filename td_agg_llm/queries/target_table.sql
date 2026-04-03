SELECT
  table_name 
FROM
  information_schema.columns
WHERE
  table_schema = 'cdp_unification_${unification_name}'
  AND REGEXP_LIKE(table_name,'^enriched_') 
GROUP BY
  1