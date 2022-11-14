select
  uid
  ,max_by(ftr, n) as ftr
  ,1 as val
from (
  select
    ${ftr.id} as uid
    ,${ftr.colmuns} as ftr
    ,count(*) as n
  from
    ${ftr.db}.${ftr.tbl}
  where
    ${ftr[params].feature_time_range}
    AND ${ftr.colmuns} is not NULL
    AND ${ftr.id} is not NULL
    ${(Object.prototype.toString.call(ftr.negative_condition) === '[object Array]')?'AND '+ftr.negative_condition.join():''}
  group by
    1,2
) t
group by
  1
