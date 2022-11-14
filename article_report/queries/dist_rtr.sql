WITH t1 AS (
  SELECT
    td_path,
    COUNT(*) AS "0",
    SUM(CASE
        WHEN (read_depth >= 10) THEN 1 ELSE 0 END) AS "10",
    SUM(CASE
        WHEN (read_depth >= 20) THEN 1 ELSE 0 END) AS "20",
    SUM(CASE
        WHEN (read_depth >= 30) THEN 1 ELSE 0 END) AS "30",
    SUM(CASE
        WHEN (read_depth >= 40) THEN 1 ELSE 0 END) AS "40",
    SUM(CASE
        WHEN (read_depth >= 50) THEN 1 ELSE 0 END) AS "50",
    SUM(CASE
        WHEN (read_depth >= 60) THEN 1 ELSE 0 END) AS "60",
    SUM(CASE
        WHEN (read_depth >= 70) THEN 1 ELSE 0 END) AS "70",
    SUM(CASE
        WHEN (read_depth >= 80) THEN 1 ELSE 0 END) AS "80",
    SUM(CASE
        WHEN (read_depth >= 90) THEN 1 ELSE 0 END) AS "90",
    SUM(CASE
        WHEN (read_depth = 100) THEN 1 ELSE 0 END) AS "100",
    SUM(instance) AS content_viewed
  FROM (
    SELECT
      'dum' AS td_path ,
      root_id ,
      max(read) as read_depth ,
      1 as instance
    FROM (
      SELECT
        td_path ,
        td_sessionize_window(time, 600) OVER(PARTITION BY ${key_id},td_path ORDER BY time) AS root_id ,
        ${read_col} AS read ,
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
    GROUP BY
      td_path,
      root_id
  )
  GROUP BY
    td_path
)

, t2 AS (
  SELECT '0' AS key, "0" AS value, '${indicator}' AS type FROM t1
  UNION ALL
  SELECT '10' AS key, "10" AS value, '${indicator}' AS type FROM t1
  UNION ALL
  SELECT '20' AS key, "20" AS value, '${indicator}' AS type FROM t1
  UNION ALL
  SELECT '30' AS key, "30" AS value, '${indicator}' AS type FROM t1
  UNION ALL
  SELECT '40' AS key, "40" AS value, '${indicator}' AS type FROM t1
  UNION ALL
  SELECT '50' AS key, "50" AS value, '${indicator}' AS type FROM t1
  UNION ALL
  SELECT '60' AS key, "60" AS value, '${indicator}' AS type FROM t1
  UNION ALL
  SELECT '70' AS key, "70" AS value, '${indicator}' AS type FROM t1
  UNION ALL
  SELECT '80' AS key, "80" AS value, '${indicator}' AS type FROM t1
  UNION ALL
  SELECT '90' AS key, "90" AS value, '${indicator}' AS type FROM t1
  UNION ALL
  SELECT '100' AS key, "100" AS value, '${indicator}' AS type FROM t1
)

SELECT
  key AS read_key,
  value AS read_value ,
  type ,
  CAST(value AS DOUBLE) / CAST(total_value AS DOUBLE) AS read_percent ,
  '${td.each.article_key}' AS article_key
FROM (
  SELECT
    key ,
    value ,
    type ,
    SUM(value) OVER (PARTITION BY dum) AS total_value
  FROM (
    SELECT
      CAST(key AS bigint) AS key ,
      value ,
      type ,
      '1' AS dum
    FROM
      t2
  )
)
