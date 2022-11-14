WITH t1 AS (
  SELECT
    td_path  ,
    root_id ,
    read_rate ,
    1.0*MAX(time) OVER (PARTITION BY root_id) - 1.0*MIN(time) OVER (PARTITION BY root_id) AS diff
  FROM (
    SELECT
      time ,
      td_path ,
      td_sessionize_window(time, 600) OVER(PARTITION BY ${key_id},td_path ORDER BY time) AS root_id ,
      CAST(${read_col} AS bigint) AS read_rate,
      td_user_agent
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
    regexp_like(td_path,'${td.each.article_id}') AND
    TD_PARSE_AGENT(td_user_agent) ['category'] = '${indicator}'
)

, t2 AS (
  SELECT
    td_path ,
    root_id,
    diff ,
    max(read_rate) as read_depth,
    1 as instance
  FROM
    t1
  WHERE
    diff <= 3600
  GROUP BY
    td_path ,
    root_id ,
    diff
)

SELECT
  a.read_key ,
  b.read_avg_browsing_time ,
  b.read_var_browsing_time ,
  '${indicator}' AS type ,
  '${td.each.article_key}' AS article_key
FROM (
  SELECT 0 AS read_key 
  UNION
  SELECT 10 AS read_key 
  UNION
  SELECT 20 AS read_key
  UNION
  SELECT 30 AS read_key 
  UNION
  SELECT 40 AS read_key 
  UNION
  SELECT 50 AS read_key 
  UNION
  SELECT 60 AS read_key 
  UNION
  SELECT 70 AS read_key 
  UNION
  SELECT 80 AS read_key
  UNION
  SELECT 90 AS read_key 
  UNION
  SELECT 100 AS read_key 
) a
LEFT JOIN (
  SELECT
    read_depth AS read_key,
    AVG(diff) AS read_avg_browsing_time,
    VARIANCE(diff) AS read_var_browsing_time 
  FROM 
    t2
  GROUP BY 
    1
  ) b
ON 
  a.read_key = b.read_key



