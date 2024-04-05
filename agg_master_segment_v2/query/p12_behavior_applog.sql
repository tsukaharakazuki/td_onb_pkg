SELECT
  'app' AS behavior_type ,
  IF(user_id_comp is not NULL, user_id_comp, ${media[params].key_id_app}) AS td_ms_id ,
  IF(user_id_comp is not NULL, 'user_id', 'device_id') AS td_ms_id_type ,
  ${media[params].set_td_url_app} AS td_url ,
  ${media[params].engagement_vols_app} AS engagement_vols ,
  'app' AS td_client_id ,
  'UNKNOWN' AS td_browser ,
  'app' AS td_host ,
  *
FROM
  ${media[params].applog_db}.${media[params].applog_tbl}
WHERE
  ${time_filter}
  ${(Object.prototype.toString.call(media[params].where_condition_app.condition) === '[object Array]')?'AND '+media[params].where_condition_app.condition.join():''}
  
