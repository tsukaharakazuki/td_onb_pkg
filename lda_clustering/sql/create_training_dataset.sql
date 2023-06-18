select
  uid
  ,json_format(cast(map_agg(val, n) as json)) as features
  ,${session_unixtime} as time
from (
  select
    uid
    ,val
    ,count(*) as n
  from (
    select
      ${set[params].id} as uid
      ,${set[params].val} as val
      ,time
    from
      ${set[params].db}.${set[params].tbl}
    where
      td_interval(time, '-${set[params].param.interval}d/${set[params].param.base_date}', 'JST')
      AND ${set[params].id} is not NULL
      ${(Object.prototype.toString.call(set[params].where_condition) === '[object Array]')?'AND '+set[params].where_condition.join(' AND '):''}
    group by
      1,2,3
    having
      count(*) >= ${set[params].param.at_least}
  ) t
  group by
    1,2
) t
group by
  1
