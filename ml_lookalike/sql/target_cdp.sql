with positive as (
  SELECT
    segment_val AS target_id
  FROM
    ${cdp[params].db}.${cdp[params].tbl}
  WHERE
    segment_name = '${td.each.segment_name}'
)
, negative as (
  select
    ${cdp[params].negative_id} AS target_id
  from
    ${cdp[params].negative_db}.${cdp[params].negative_tbl}
  WHERE
    ${cdp[params].negative_time_range}
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


