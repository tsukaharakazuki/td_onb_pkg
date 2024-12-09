SELECT
  ${web[param].key_id} as key_id ,
  ${func}(${val}) AS td_${output} 
FROM
  ${web[param].db}.${web[param].tbl}
WHERE
  ${web[param].key_id} is not NULL
  AND TD_INTERVAL(time,'-${web[param].date_range}d','${time_zone}')
GROUP BY
  1