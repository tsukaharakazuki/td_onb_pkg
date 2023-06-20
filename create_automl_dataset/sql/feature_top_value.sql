WITH t0 AS (
  SELECT
    * ,
    CAST(ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY c desc) AS VARCHAR) AS key
  FROM (
    SELECT
      ${set.id} AS user_id ,
      ${set.colmuns} AS value ,
      ${set.val} AS c
    FROM
      ${set.db}.${set.tbl}
    WHERE
      ${set[params].feature_time_range}
      AND ${set.null_check_col} is not NULL
      AND ${set.id} is not NULL
      ${(Object.prototype.toString.call(set.where_condition) === '[object Array]')?'AND '+set.where_condition.join(' AND '):''}
    ${(Object.prototype.toString.call(set.insert_groupby) === '[object Array]')?'GROUP BY '+set.insert_groupby.join():''}
  )
)

SELECT 
  user_id,
  ${td.last_results.set_rank}
FROM 
  t0
GROUP BY 
  user_id

