WITH t0 AS (
  SELECT
    'app' AS behavior_type ,
    ${media[params].set_td_url_app} AS td_url ,
    ${media[params].engagement_vols_app} AS engagement_vols ,
    'app' AS td_client_id ,
    'UNKNOWN' AS td_browser ,
    'app' AS td_host ,
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
)

SELECT
  IF(b.user_id is not NULL, CAST(b.user_id AS VARCHAR), a.${media[params].key_id_app}) AS td_ms_id ,
  IF(b.user_id is not NULL, 'user_id', 'cookie') AS td_ms_id_type ,
  a.*
FROM
  t0 a
LEFT JOIN
  ${media[params].output_db}.map_cookie_uid_${media[params].media_name} b
ON
  a.${media[params].key_id_app} = b.${media[params].key_id_app}