WITH t0 AS (
  SELECT
    'web' AS behavior_type ,
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
    ${(Object.prototype.toString.call(media[params].where_condition_web.condition) === '[object Array]')?'AND '+media[params].where_condition_web.condition.join(' AND '):''}
)

SELECT
  IF(b.user_id is not NULL, CAST(b.user_id AS VARCHAR), a.${media[params].key_id_web}) AS td_ms_id ,
  IF(b.user_id is not NULL, 'user_id', 'cookie') AS td_ms_id_type ,
  a.*
FROM
  t0 a
LEFT JOIN
  ${media[params].output_db}.map_cookie_uid_${media[params].media_name} b
ON
  a.${media[params].key_id_web} = b.${media[params].key_id_web}