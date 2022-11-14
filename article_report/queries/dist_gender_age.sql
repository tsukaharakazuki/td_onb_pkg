WITH target AS (
  SELECT
    DISTINCT ${key_id} AS target
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

SELECT
  gender ,
  age ,
  COUNT(*) AS population ,
  '${td.each.article_key}' AS article_key
FROM (
  SELECT
    a.target ,
    b.pred ,
    b.gender ,
    b.age
  FROM
    target a
  LEFT JOIN
    mst_gender_age b
  ON
    a.target = b.target
)
GROUP BY
  1,2