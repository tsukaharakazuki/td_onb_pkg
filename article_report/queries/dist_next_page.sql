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

, tmp_next AS (
  SELECT
    a.${key_id} ,
    td_path ,
    td_title ,
    LEAD(td_title) OVER (PARTITION BY a.${key_id} ORDER BY a.time ASC) AS next_title ,
    LEAD(td_path) OVER (PARTITION BY a.${key_id} ORDER BY a.time ASC) AS next_path 
  FROM
    ${log_db}.${log_tbl} a
  INNER JOIN
    access_cookie b
  ON
    a.${key_id} = b.${key_id}
  WHERE
    td_host = '${td.each.target_host}' AND
    TD_TIME_RANGE(a.time,
      '${td.each.start_date}',
      '${td.each.end_date}',
      'JST'
    ) 
)

SELECT
  rnk ,
  next_title ,
  next_path ,
  pv ,
  uu ,
  '${td.each.article_key}' AS article_key
FROM (
  SELECT
    RANK() OVER(ORDER BY pv DESC) AS rnk ,
    next_title ,
    next_path ,
    pv ,
    uu
  FROM (
    SELECT
      next_title ,
      next_path ,
      COUNT(*) AS pv ,
      COUNT(DISTINCT ${key_id}) AS uu
    FROM
      tmp_next
    WHERE
      regexp_like(td_path,'${td.each.article_id}')
      AND next_title is not NULL 
      AND next_path <> '/'
    GROUP BY
      1,2
  )
)
WHERE
  rnk <= 50
