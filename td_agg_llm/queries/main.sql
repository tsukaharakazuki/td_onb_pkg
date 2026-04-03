SELECT
  *
FROM
  ${datas[param].db}.${datas[param].tbl}
WHERE
  true
  ${(Object.prototype.toString.call(datas[param].where_condition) === '[object Array]')?'AND '+datas[param].where_condition.join(' AND '):''}