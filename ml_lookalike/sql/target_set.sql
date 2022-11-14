with positive as (
  select
    ${set[params].target_id} AS target_id
  from
    ${set[params].target_db}.${set[params].target_tbl}
  WHERE
    ${set[params].target_time_range}
    ${(Object.prototype.toString.call(set[params].target_positive.condition) === '[object Array]')?'AND '+set[params].target_positive.condition.join():''}
  group by
    1
)
, negative as (
  select
    ${set[params].target_id} AS target_id
  from
    ${set[params].target_db}.${set[params].target_tbl}
  WHERE
    ${set[params].target_time_range}
  group by
    1
)

select
  target_id as uid
  , max(target) as target
from (
  select target_id, 1 as target from positive
  union all
  select target_id, 0 as target from negative
) t
group by
  1
