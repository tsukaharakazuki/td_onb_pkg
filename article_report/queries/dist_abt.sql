SELECT
  AVG(browsing_time) AS avg_browsing_time ,
  APPROX_PERCENTILE(browsing_time, 0.5) AS median_browsing_time ,
  VARIANCE(browsing_time) AS var_browsing_time ,
  '${td.each.article_key}' AS article_key
FROM (
  SELECT
    td_path ,
    (next_time - time) * 1.0 AS browsing_time
  FROM (
    SELECT
      ${key_id} ,
      time ,
      td_path  ,
      LEAD(time) OVER (PARTITION BY ${key_id} ORDER BY time) AS next_time 
    FROM
      ${log_db}.${log_tbl}
    WHERE
      td_host = '${td.each.target_host}' AND
      TD_TIME_RANGE(time,
        '${td.each.start_date}',
        '${td.each.end_date}',
        'JST'
      ) 
    ORDER BY 
      time
  ) t1
  WHERE 
    regexp_like(td_path,'${td.each.article_id}')
) 
WHERE 
  browsing_time < 600
  AND browsing_time is not NULL
