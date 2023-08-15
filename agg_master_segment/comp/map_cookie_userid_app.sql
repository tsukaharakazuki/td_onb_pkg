SELECT
  ${media[params].key_id_app} ,
  user_id ,
  MAX(time) AS time
FROM
  ${media[params].applog_db}.${media[params].applog_tbl}
WHERE
  user_id is not NULL
GROUP BY
  1,2