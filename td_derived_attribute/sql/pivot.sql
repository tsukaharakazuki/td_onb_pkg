WITH t0 AS (
  SELECT
    ${set.id} as key_id ,
    ${set.key} AS key ,
    ${set.value} AS value 
  FROM
    ${set.db}.${set.tbl}
  WHERE
    true
    AND ${set.null_check_col} is not NULL
    AND ${set.id} is not NULL
    ${(Object.prototype.toString.call(set.where_condition) === '[object Array]')?'AND '+set.where_condition.join(' AND '):''}
  GROUP BY
    1,2
)

-- DIGDAG_INSERT_LINE
SELECT 
  key_id,
  ${td.last_results.set_case}
FROM 
  t0
GROUP BY 
  key_id