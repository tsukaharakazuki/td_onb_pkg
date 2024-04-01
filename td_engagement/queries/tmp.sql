SELECT
  ${key_id} AS user_id ,
  COUNT(*) AS pv ,
  CAST((TD_DATE_TRUNC('day',unix_timestamp()) - TD_DATE_TRUNC('day',MIN(time))) / 86400 AS INT) AS td_progress ,
  CAST((TD_DATE_TRUNC('day',MAX(time)) - TD_DATE_TRUNC('day',unix_timestamp())) / 86400 AS INT) AS td_recency ,
  COUNT(DISTINCT TD_TIME_FORMAT(time,'yyyy-MM-dd','JST')) AS td_frequency ,
  COUNT(DISTINCT td_path) AS td_volume ,
  MIN(time) AS time 
FROM
  ${weblog_db}.${weblog_tbl}
WHERE
  ${val.time_filter}
  AND ${key_id} is not NULL
GROUP BY
  1