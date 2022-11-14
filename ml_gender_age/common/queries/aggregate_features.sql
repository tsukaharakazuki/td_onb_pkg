select
  uid
  ,json_format(cast(map_agg(i2f.id, f.val) as json)) as features
  ,cast(floor(rand() / (1.0 / ${ml.n_split})) as int) as nth_group
from
  features f
  inner join
  id2feature i2f
  on
    f.ftr = i2f.ftr
where
  id < ${ml.n_features}
group by
  1
