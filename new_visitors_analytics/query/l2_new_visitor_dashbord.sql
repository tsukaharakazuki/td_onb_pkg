SELECT
  TD_TIME_FORMAT(time,'yyyy','JST') AS year ,
  TD_TIME_FORMAT(time,'yyyy-MM','JST') AS month ,
  TD_TIME_FORMAT(time,'yyyy-MM-dd','JST') AS date 
  ${(Object.prototype.toString.call(media[params].add_columns) === '[object Array]')?','+media[params].add_columns.join():''}
  , td_source ,
  td_medium ,
  td_campaign ,
  COUNT(*) AS uu
FROM
  l1_new_visitor
GROUP BY
  time 
  ${(Object.prototype.toString.call(media[params].add_columns) === '[object Array]')?','+media[params].add_columns.join():''}
  , td_source ,
  td_medium ,
  td_campaign 
