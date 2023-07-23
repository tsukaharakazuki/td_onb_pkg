select
  ${ftr.id} as uid
  ,${ftr.colmuns} as ftr
  ,1 as val
from
  ${ftr.db}.${ftr.tbl}
where
  ${ftr.colmuns} is not NULL
  AND ${ftr.id} is not NULL
