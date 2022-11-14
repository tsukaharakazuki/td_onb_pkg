SELECT
  TD_TIME_FORMAT(time,'EEEE','JST') AS dow ,
  CASE
    WHEN TD_TIME_FORMAT(time,'EEEE','JST') = 'Sunday' THEN 1
    WHEN TD_TIME_FORMAT(time,'EEEE','JST') = 'Monday' THEN 2
    WHEN TD_TIME_FORMAT(time,'EEEE','JST') = 'Tuesday' THEN 3
    WHEN TD_TIME_FORMAT(time,'EEEE','JST') = 'Wednesday' THEN 4
    WHEN TD_TIME_FORMAT(time,'EEEE','JST') = 'Thursday' THEN 5
    WHEN TD_TIME_FORMAT(time,'EEEE','JST') = 'Friday' THEN 6
    WHEN TD_TIME_FORMAT(time,'EEEE','JST') = 'Saturday' THEN 7
  END dow_flag ,
  COUNT(*) AS pv ,
  COUNT(DISTINCT ${key_id}) AS uu ,
  '${td.each.article_key}' AS article_key
FROM
  ${log_db}.${log_tbl}
WHERE
  td_host = '${td.each.target_host}' AND
  regexp_like(td_path,'${td.each.article_id}') AND
  TD_TIME_RANGE(time,
    '${td.each.start_date}',
    '${td.each.end_date}',
    'JST'
  ) 
GROUP BY 
  1