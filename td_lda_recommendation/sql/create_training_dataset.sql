select
  uid
  ,json_format(cast(map_agg(val, n) as json)) as features
  ,${session_unixtime} as time
from 
  tmp_train_ds_${set[params].name}
group by
  1
