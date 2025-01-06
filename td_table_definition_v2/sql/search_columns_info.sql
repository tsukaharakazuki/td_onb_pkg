WITH t0 AS (
  SELECT
    * ,
    IF(
      REGEXP_LIKE(data_type,'^array') ,
      'ARRAY_JOIN('||column_name||','','') ' ,
      'CAST('||column_name||' AS VARCHAR)'
      ) AS tmp_case
  FROM
    information_schema.columns
  WHERE
    table_schema = '${database}'
    AND table_name = 'td_sample_data'
)

SELECT
  ARRAY_JOIN(
    ARRAY_AGG(
      'SELECT '''||column_name||''' AS key ,'||tmp_case||' AS value FROM td_sample_data'
      ) ,
    ' UNION ALL '
  ) AS sql_contents
FROM
  t0
