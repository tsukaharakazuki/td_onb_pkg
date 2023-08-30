SELECT
  key_id ,
  CAST(TRUNCATE((MAX(time)- TO_UNIXTIME(now()))/ 86400) AS INT) AS recency,
  COUNT(DISTINCT TD_TIME_FORMAT(time,'yyyy-MM-dd','JST')) AS frequency,
  SUM(amount) AS monetary ,
  MIN(time) AS first_order_unix  ,
  MAX(time) AS last_order_unix ,
  TD_TIME_FORMAT(MIN(time),'yyyy-MM-dd HH:mm:ss','JST') AS first_order_date ,
  TD_TIME_FORMAT(MAX(time),'yyyy-MM-dd HH:mm:ss','JST') AS last_order_date 
FROM
  db.tbl
GROUP BY
  1
