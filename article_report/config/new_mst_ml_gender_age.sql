SELECT
  cookie AS target ,
  MAX_BY(pred, time) AS pred ,
  CASE
    WHEN MAX_BY(pred,time) LIKE 'M%' THEN '男性'
    WHEN MAX_BY(pred,time) LIKE 'F%' THEN '女性'
    WHEN MAX_BY(pred,time) = 'C' THEN '子ども'
  END gender ,
  SUBSTR(MAX_BY(pred,time), 2,3) AS age
FROM
  ${user_data_db}.${user_data_tbl}
GROUP BY
  1