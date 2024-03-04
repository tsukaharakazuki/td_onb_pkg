SELECT
  'web' AS behavior_type ,
  IF(user_id_comp is not NULL, user_id_comp, ${media[params].key_id_web}) AS td_ms_id ,
  IF(user_id_comp is not NULL, 'user_id', 'cookie') AS td_ms_id_type ,
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
	TD_TIME_RANGE(
    time ,
    NULL ,
    TD_TIME_FORMAT(TD_SCHEDULED_TIME(), 'yyyy-MM-dd', 'JST') ,
    'JST'
	)
  ${(Object.prototype.toString.call(media[params].where_condition_web.condition) === '[object Array]')?'AND '+media[params].where_condition_web.condition.join(' AND '):''}
