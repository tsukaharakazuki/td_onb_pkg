SELECT
  'web' AS behavior_type ,
  ${media[params].key_id_web} AS td_ms_id ,
  ${media[params].set_td_url_web} AS td_url ,
  td_url AS td_url_raw ,
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
