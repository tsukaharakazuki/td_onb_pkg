select
  uid
  ,val
  ,count(*) as n
from (
  select
    ${prm.id} as uid
    ,'TD_SUB_'||${prm.val} as val
    ,time
  from
    ${prm.db}.${prm.tbl}
  where
    td_interval(time, '-${set[params].param.interval}d/${set[params].param.base_date}', 'JST')
    AND ${prm.id} is not NULL
    ${(Object.prototype.toString.call(prm.where_condition) === '[object Array]')?'AND '+prm.where_condition.join(' AND '):''}
  group by
    1,2,3
  having
    count(*) >= ${set[params].param.at_least}
) t
group by
  1,2