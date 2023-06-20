select
  ${set.id} as user_id
  ,${set.colmuns} as ftr1_${set.output}
from
  ${set.db}.${set.tbl}
where
  ${set[params].feature_time_range}
  AND ${set.null_check_col} is not NULL
  AND ${set.id} is not NULL
  ${(Object.prototype.toString.call(set.where_condition) === '[object Array]')?'AND '+set.where_condition.join(' AND '):''}
${(Object.prototype.toString.call(set.insert_groupby) === '[object Array]')?'GROUP BY '+set.insert_groupby.join():''}