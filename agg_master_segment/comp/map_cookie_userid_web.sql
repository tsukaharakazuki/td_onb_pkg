SELECT
  ${media[params].key_id_web} ,
  user_id ,
  MAX(time) AS time
FROM
  ${media[params].weblog_db}.${media[params].weblog_tbl}
WHERE
  user_id is not NULL
GROUP BY
  1,2