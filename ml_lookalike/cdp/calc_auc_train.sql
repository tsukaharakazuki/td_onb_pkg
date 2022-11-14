select
  f.uid
  ,t.target
  ,f.features
  ,case when rand() < 0.8 then 0 else 1 end as is_test
from
  preprocessed_${td.each.segment_tbl} f
  inner join
  target_${td.each.segment_tbl} t
  on
    f.uid = t.uid
