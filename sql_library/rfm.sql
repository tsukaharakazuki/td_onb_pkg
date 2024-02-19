SELECT
  key_id ,
  CAST(TRUNCATE((MAX(time)- TO_UNIXTIME(now()))/ 86400) AS INT) * -1 AS recency_rfm ,
  --CAST(((MAX(time)- TD_SCHEDULED_TIME())/ 86400) AS INT) * -1 AS recency_rfm ,
  COUNT(DISTINCT TD_TIME_FORMAT(time,'yyyy-MM-dd','JST')) AS frequency_rfm ,
  SUM(amount) AS monetary_rfm ,
  MIN(time) AS first_order_unix_rfm  ,
  MAX(time) AS last_order_unix_rfm ,
  TD_TIME_FORMAT(MIN(time),'yyyy-MM-dd HH:mm:ss','JST') AS first_order_date_rfm ,
  TD_TIME_FORMAT(MAX(time),'yyyy-MM-dd HH:mm:ss','JST') AS last_order_date_rfm 
FROM
  db.tbl
GROUP BY
  1
