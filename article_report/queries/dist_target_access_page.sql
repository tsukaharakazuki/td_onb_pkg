WITH access_cookie AS (
  SELECT
    DISTINCT ${key_id} 
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
)

, tmp_access AS (
  SELECT
    a.${key_id} ,
    td_path ,
    td_title 
  FROM
    ${log_db}.${log_tbl} a
  INNER JOIN
    access_cookie b
  ON
    a.${key_id} = b.${key_id}
  WHERE
    TD_TIME_RANGE(a.time,
      '${td.each.start_date}',
      '${td.each.end_date}',
      'JST'
    ) 
)

SELECT
  rnk ,
  td_path ,
  td_title ,
  pv ,
  uu ,
  '${td.each.article_key}' AS article_key
FROM (
  SELECT
    RANK() OVER(ORDER BY pv DESC) AS rnk ,
    td_path ,
    td_title ,
    pv ,
    uu
  FROM (
    SELECT
      td_path ,
      td_title ,
      COUNT(*) AS pv ,
      COUNT(DISTINCT ${key_id}) AS uu
    FROM
      tmp_access
    WHERE
      NOT regexp_like(td_path,'${td.each.article_id}') AND
      td_path <> '/'
    GROUP BY
      1,2
  )
)
WHERE
  rnk <= 50
