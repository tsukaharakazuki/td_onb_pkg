select
  ftr
  ,count(*) as users
  ,row_number() over(order by count(*) desc) - 1 as id
from
  features f
  inner join 
  target_${td.each.segment_tbl} t
  on
    f.uid = t.uid
group by
  1
