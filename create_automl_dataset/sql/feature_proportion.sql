WITH map_ftr AS (
  SELECT
    ${set.colmuns} AS map_ftr ,
    ROW_NUMBER() OVER () AS map_ftr_num
  FROM
    ${set.db}.${set.tbl}
  WHERE
    ${set[params].feature_time_range}
    AND ${set.null_check_col} is not NULL
    AND ${set.id} is not NULL
    ${(Object.prototype.toString.call(set.where_condition) === '[object Array]')?'AND '+set.where_condition.join(' AND '):''}
  GROUP BY
    1
)

, t0 AS (
  SELECT
    a.${set.id} as user_id
    ,b.map_ftr_num AS ftr
    ,cast(count(*) as double) / sum(count(*)) over(partition by a.${set.id}) as val
  FROM (
    SELECT
      *
    FROM    
      ${set.db}.${set.tbl}
    WHERE
      ${set[params].feature_time_range}
      AND ${set.null_check_col} is not NULL
      AND ${set.id} is not NULL
      ${(Object.prototype.toString.call(set.where_condition) === '[object Array]')?'AND '+set.where_condition.join(' AND '):''}
    ) a
    INNER JOIN
    map_ftr b
    ON
      ${set.map_join_key} = b.map_ftr
  GROUP BY
    1,2
)

SELECT
  user_id ,
  '{'||
    ARRAY_JOIN(
      ARRAY_AGG(
          '"'||CAST(ftr AS VARCHAR)||'": '||CAST(val AS VARCHAR)
      ),
    ',')||
  '}' AS ftrpop_${set.output}
FROM
  t0
GROUP BY
  1