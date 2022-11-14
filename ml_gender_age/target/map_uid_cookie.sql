SELECT
  ${map_uid_cookie[params].cookie} AS cookie ,
  ${map_uid_cookie[params].uid} AS uid
FROM
  ${map_uid_cookie[params].db}.${map_uid_cookie[params].tbl}
WHERE
  ${map_uid_cookie[params].uid} is not NULL
  ${(Object.prototype.toString.call(map_uid_cookie[params].where) === '[object Array]')?'AND '+map_uid_cookie[params].where.join(' AND '):''}
GROUP BY
  1,2