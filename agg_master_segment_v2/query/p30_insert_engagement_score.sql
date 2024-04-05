SELECT
  td_ms_id ,
  MAX_BY(user_id_comp, if(user_id_comp is null,null,time)) AS user_id ,
  CAST((TD_DATE_TRUNC('day',unix_timestamp()) - TD_DATE_TRUNC('day',MIN(time))) / 86400 AS INT) AS td_progress ,
  CAST((TD_DATE_TRUNC('day',MAX(time)) - TD_DATE_TRUNC('day',unix_timestamp())) / 86400 AS INT) AS td_recency ,
  COUNT(DISTINCT TD_TIME_FORMAT(time,'yyyy-MM-dd','JST')) AS td_frequency ,
  COUNT(DISTINCT engagement_vols) AS td_volume ,
  MIN(time) AS time ,
  2 AS dum
  ${(Object.prototype.toString.call(media[params].add_engagement_calc.sql) === '[object Array]')?','+media[params].add_engagement_calc.sql.join():''}
FROM (
  SELECT
    * ,
    ROW_NUMBER() OVER (PARTITION BY td_ms_id ORDER BY time ASC) AS num
  FROM
    ${media[params].output_db}.ms_behavior_${media[params].media_name}
  WHERE
    TD_INTERVAL(time,'-1d','JST')
) t
GROUP BY
  1
