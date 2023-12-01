SELECT
  ${web.time_col} AS time ,
  ${web.time_col} AS time_inflow ,
  ${web.user_id} AS user_id ,
  ${web.utm_source} AS td_source,
  ${web.utm_medium} AS td_medium,
  ${web.utm_campaign} AS td_campaign ,
  --CONCAT(COALESCE(${web.utm_source} ,''),' ', COALESCE(${web.utm_medium} ,''),' ', COALESCE(${web.utm_campaign} ,'')) AS td_smc
  COALESCE(${web.utm_source} ,'')||' '||COALESCE(${web.utm_medium} ,'')||' '||COALESCE(${web.utm_campaign} ,'') AS td_smc
FROM
  ${web.db}.${web.tbl} 
WHERE
  session_num = 1
  AND ${web.user_id} is not NULL
  AND TD_INTERVAL(${web.time_col},'-1d','JST')
  ${(Object.prototype.toString.call(web.where_condition) === '[object Array]')?'AND '+web.where_condition.join(' AND '):''}