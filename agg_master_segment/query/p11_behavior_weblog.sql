SELECT
  'web' AS behavior_type ,
  IF(user_id_comp is not NULL, user_id_comp, ${media[params].key_id_web}) AS td_ms_id ,
  ${media[params].set_td_url_web} AS td_url ,
  td_url AS td_url_raw ,
  utm_campaign AS ms_utm_campaign ,
  utm_medium AS ms_utm_medium ,
  utm_source AS ms_utm_source ,
  ${media[params].engagement_vols_web} AS engagement_vols
  ${td.last_results.set_columns}
FROM
  ${media[params].weblog_db}.${media[params].weblog_tbl}
WHERE
  TD_INTERVAL(time, '-${log_span}/now', 'JST')
  ${(Object.prototype.toString.call(media[params].where_condition_web.condition) === '[object Array]')?'AND '+media[params].where_condition_web.condition.join():''}
  
