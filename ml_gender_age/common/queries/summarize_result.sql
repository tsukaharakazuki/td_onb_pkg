select
  t.target as target
  ,p.pred as predicted
  ,is_test
  ,count(*) as users
  ,sum(if(t.target = p.pred, 1, 0)) as correct_users
  ,${session_unixtime} as time
from
  predicted p
  left outer join
  train t
  on
    p.uid = t.uid
where
  td_time_range(p.time,
    '${date}',
    '${moment(date).add(1, "days").format("YYYY-MM-DD")}',
    '${timezone}' 
  )
group by
  1,2,3
