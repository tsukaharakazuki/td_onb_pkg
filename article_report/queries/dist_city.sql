WITH t0 AS (
  SELECT
    ip_city ,
    pv ,
    uu ,
    RANK() OVER(ORDER BY pv DESC) AS rnk
  FROM (
    SELECT
      REGEXP_REPLACE(
        REGEXP_REPLACE(
          TD_IP_TO_CITY_NAME(td_ip)
        , '^Ō', 'O')
      , 'ō', 'o') AS ip_city ,
      COUNT(*) AS pv ,
      COUNT(DISTINCT ${key_id}) AS uu 
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
  )
)

SELECT
  ip_city ,
  pv ,
  uu ,
  '${td.each.article_key}' AS article_key
FROM
  t0
WHERE
  rnk <= 50
