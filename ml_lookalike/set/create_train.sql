select
  f.uid
  ,t.target
  ,f.features
  ,case when rand() < 0.8 then 0 else 1 end as is_test
from
  preprocessed_${set[params].name} f
  inner join
  target_${set[params].name} t
  on
    f.uid = t.uid
