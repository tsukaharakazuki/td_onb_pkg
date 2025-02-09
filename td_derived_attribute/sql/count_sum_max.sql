SELECT
  ${set.id} as key_id ,
  ${set.func}(${set.val}) AS td_${set.output} 
FROM
  ${set.db}.${set.tbl}
WHERE
  ${set.id} is not NULL
  ${(Object.prototype.toString.call(set.where_condition) === '[object Array]')?'AND '+set.where_condition.join(' AND '):''}
GROUP BY
  1
