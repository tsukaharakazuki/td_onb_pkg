WITH t0 AS (
  SELECT
    ${set.id} as user_id ,
    ${set.colmuns} AS val ,
    CASE
      WHEN COUNT(*) ${set.conditions1} THEN '${set.output}${set.name1}'
      WHEN COUNT(*) ${set.conditions2} THEN '${set.output}${set.name2}'
      WHEN COUNT(*) ${set.conditions3} THEN '${set.output}${set.name3}'
      WHEN COUNT(*) ${set.conditions4} THEN '${set.output}${set.name4}'
    END key 
  FROM
    ${set.db}.${set.tbl}
  WHERE
    ${set[params].feature_time_range}
    AND ${set.colmuns} is not NULL
    AND ${set.id} is not NULL
    ${(Object.prototype.toString.call(set.where_condition) === '[object Array]')?'AND '+set.where_condition.join(' AND '):''}
  GROUP BY 
    1,2
)

, t1 AS (
  SELECT
    user_id ,
    key ,
    ARRAY_JOIN(ARRAY_AGG(val),',') AS vals
    --ARRAY_AGG(val) AS vals
  FROM
    t0
  GROUP BY
    1,2
)


SELECT 
  user_id,
  MAX(CASE WHEN key = '${set.output}${set.name1}' THEN vals END) AS ftr4_${set.output}${set.name1} ,
  MAX(CASE WHEN key = '${set.output}${set.name2}' THEN vals END) AS ftr4_${set.output}${set.name2} ,
  MAX(CASE WHEN key = '${set.output}${set.name3}' THEN vals END) AS ftr4_${set.output}${set.name3} , 
  MAX(CASE WHEN key = '${set.output}${set.name4}' THEN vals END) AS ftr4_${set.output}${set.name4}  
FROM 
  t1
GROUP BY
  1