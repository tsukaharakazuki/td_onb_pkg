SELECT
  ${media[params].key_id} 
  ${(Object.prototype.toString.call(media[params].add_columns) === '[object Array]')?','+media[params].add_columns.join():''}
  , MIN(time) AS time ,
  MIN_BY(td_source,time) AS td_source ,
  MIN_BY(td_medium,time) AS td_medium ,
  MIN_BY(td_campaign,time) AS td_campaign
FROM
  l1_new_visitor_tmp
GROUP BY
  ${media[params].key_id} 
  ${(Object.prototype.toString.call(media[params].add_columns) === '[object Array]')?','+media[params].add_columns.join():''}
