WITH t0 AS (
  SELECT
    ${set.id} as user_id ,
    ${set.colmuns} AS key ,
    ${set.val} AS value 
  FROM
    ${set.db}.${set.tbl}
  WHERE
    ${set[params].feature_time_range}
    AND ${set.null_check_col} is not NULL
    AND ${set.id} is not NULL
    ${(Object.prototype.toString.call(set.where_condition) === '[object Array]')?'AND '+set.where_condition.join(' AND '):''}
  ${(Object.prototype.toString.call(set.insert_groupby) === '[object Array]')?'GROUP BY '+set.insert_groupby.join():''}
)

SELECT 
  user_id,
  ${td.last_results.set_case}
FROM 
  t0
GROUP BY 
  user_id