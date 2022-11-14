WITH u1 AS (
  SELECT
    root_id ,
    TD_TIME_FORMAT(MIN(time), 'yyyyMMdd', 'JST') AS d ,
    TD_TIME_FORMAT(MIN(time), 'HH', 'JST') AS h ,
    max(read) AS max_rd
  FROM (
    SELECT
      time ,
      td_sessionize_window(time, 600) OVER(PARTITION BY ${key_id},td_path ORDER BY time) AS root_id ,
      ${read_col} AS read ,
      td_path
    FROM
      ${read_db}.${read_tbl}
    WHERE
      td_host = '${td.each.target_host}' AND
      TD_TIME_RANGE(time,
        '${td.each.start_date}',
        '${td.each.end_date}',
        'JST'
      ) 
  )
  WHERE
    regexp_like(td_path,'${td.each.article_id}')
  GROUP BY 
    1
)

SELECT
  h AS hour,
  AVG(max_rd) AS read_avg_browsing_time ,
  '${td.each.article_key}' AS article_key
FROM 
  u1
GROUP BY 
  1