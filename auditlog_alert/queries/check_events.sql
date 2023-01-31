SELECT 
  TD_TIME_FORMAT(time,'yyyy-MM-dd HH:mm:ss', 'JST') AS date ,
  *
FROM
  ${db}.${tbl}
WHERE
  TD_INTERVAL(time, '-${span}/now', 'JST')
  ${(Object.prototype.toString.call(events[params].config) === '[object Array]')?'AND '+events[params].config.join(' AND '):''}