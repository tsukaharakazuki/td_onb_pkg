SELECT
  'app' AS behavior_type ,
  ${media[params].key_id_app} AS td_ms_id ,
  ${media[params].set_td_url_app} AS td_url ,
  ${media[params].engagement_vols_app} AS engagement_vols ,
  *
FROM
  ${media[params].applog_db}.${media[params].applog_tbl}
WHERE
	TD_TIME_RANGE(
			time ,
			NULL ,
			TD_TIME_FORMAT(TD_SCHEDULED_TIME(), 'yyyy-MM-dd', 'JST') ,
			'JST'
	)
  ${(Object.prototype.toString.call(media[params].where_condition_app.condition) === '[object Array]')?'AND '+media[params].where_condition_app.condition.join():''}
  
