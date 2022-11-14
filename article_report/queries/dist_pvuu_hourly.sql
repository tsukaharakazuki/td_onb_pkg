WITH t1 AS (
  SELECT
    TD_TIME_FORMAT(time, 'yyyyMMdd', 'JST') AS date ,
    TD_TIME_FORMAT(time, 'HH', 'JST') AS hour ,
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
    1,2
)

SELECT
  hour ,
  AVG(pv) AS avg_pv ,
  AVG(uu) AS avg_uu ,
  AVG(pv) + SQRT(VARIANCE(pv)) as upper ,
  AVG(pv) - SQRT(VARIANCE(pv)) as lower ,
  '${td.each.article_key}' AS article_key
FROM 
  t1
GROUP BY
  1