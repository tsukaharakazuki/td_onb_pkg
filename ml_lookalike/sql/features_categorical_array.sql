select
  uid
  ,ftr
  ,cast(count(*) as double) / sum(count(*)) over(partition by uid) as val
from (
  SELECT
    ${ftr.id} AS uid ,
    ftr
  FROM
    ${ftr.db}.${ftr.tbl}
  CROSS JOIN 
    UNNEST(${ftr.colmuns}) AS t(ftr)
  WHERE
    ${ftr[params].feature_time_range}
    AND ${ftr.colmuns} is not NULL
    AND ${ftr.id} is not NULL
    ${(Object.prototype.toString.call(ftr.negative_condition) === '[object Array]')?'AND '+ftr.negative_condition.join():''}
)
group by
  1,2