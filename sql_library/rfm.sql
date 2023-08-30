SELECT
  key_id ,
  CAST(TRUNCATE((MAX(time)- TO_UNIXTIME(now()))/ 86400) AS INT) AS recency,
  COUNT(DISTINCT TD_TIME_FORMAT(time,'yyyy-MM-dd','JST')) AS frequency,
  SUM(amount) AS monetary
FROM
  db.tbl
GROUP BY
  1
