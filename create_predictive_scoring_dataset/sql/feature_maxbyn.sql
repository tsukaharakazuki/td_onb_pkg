WITH t0 AS (
  select
    ${set.id} as user_id
    ,${set.colmuns} as ftr 
    ,count(*) as n
  from
    ${set.db}.${set.tbl}
  where
    ${set[params].feature_time_range}
    AND ${set.null_check_col} is not NULL
    AND ${set.id} is not NULL
    ${(Object.prototype.toString.call(set.where_condition) === '[object Array]')?'AND '+set.where_condition.join(' AND '):''}
  GROUP BY
    1,2
)

select
  user_id
  ,max_by(ftr, n) as ftrnm_${set.output}
from
  t0
GROUP BY
  1