SELECT
  ${media[params].key_id} 
  ${(Object.prototype.toString.call(media[params].add_columns) === '[object Array]')?','+media[params].add_columns.join():''}
  , MIN(time) AS time ,
  MIN_BY(td_source,time) AS td_source ,
  MIN_BY(td_medium,time) AS td_medium ,
  MIN_BY(utm_campaign,time) AS td_campaign
FROM
  ${media[params].log_db}.${media[params].log_tbl}
WHERE
  session_num = 1
  AND ${time_filter}
GROUP BY
  ${media[params].key_id} 
  ${(Object.prototype.toString.call(media[params].add_columns) === '[object Array]')?','+media[params].add_columns.join():''}