with f as (
  select
    uid
    ,ftr
    ,val
  from
    -- features
    preprocessed
  union all
  select
    distinct uid
    ,0 as ftr
    ,10 as val
  from
    -- features
    preprocessed
)

-- DIGDAG_INSERT_LINE
select 
  uid, 
  m.col0 as score, 
  m.col1 as target
from (
  select
     uid, 
     maxrow(score, target) as m
  from (
    select
      f.uid,
      m.target,
      sum(m.weight * COALESCE(f.val, 0)) as score
    from
      f 
      left outer join
      model m 
      on 
        f.ftr = m.feature
    group by
      1,2
  ) t1
  group by
    1
) t2




