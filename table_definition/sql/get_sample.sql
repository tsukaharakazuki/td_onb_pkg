WITH base AS (
  SELECT
    ${td.last_results.max_col_name_columns}
  FROM
    ${td.each.database_name}.${td.each.table_name}
)

, sample_data AS (
  SELECT 
    t.col_name
    ,MAX(t.sample) AS sample
  FROM 
    base AS b
  CROSS JOIN UNNEST (
    array[${td.last_results.col_name_columns}],
    array[${td.last_results.sample_columns}]
  ) AS t (col_name, sample)
  GROUP BY 1
)

SELECT
  c.database_name
  ,c.table_name
  ,s.col_name
  ,${data_type.dt == 'array(varchar)' ? "ARRAY_JOIN(s.sample, ',') AS sample":"CAST(s.sample AS VARCHAR) AS sample"}
FROM
  tmp_columns_${flag}_${data_type.col} c
INNER JOIN
  sample_data s
ON
  c.column_name = s.col_name
WHERE
  database_name = '${td.each.database_name}'
  AND table_name = '${td.each.table_name}'
