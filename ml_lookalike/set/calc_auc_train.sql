select
  0 as is_test
  ,auc(pred, target) as auc
  ,count(*) as users
from (
  select
    pred
    ,target
  from
    predicted_${set[params].name} p
    inner join
    train_${set[params].name} t
    on
      p.uid = t.uid
  where
    td_time_range(p.time,
      '${session_date}',
      '${moment(session_date).add(1, "days").format("YYYY-MM-DD")}',
      '${timezone}' 
    )
    and
    is_test = 0
  order by
    pred desc
) t
