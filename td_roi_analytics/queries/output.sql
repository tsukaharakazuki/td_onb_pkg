SELECT
  TD_TIME_FORMAT(time,'yyyy/MM/dd','JST') AS date ,
  td_source_first ,
  td_medium_recent ,
  td_campaign_first ,
  IF(REGEXP_LIKE(td_campaign_first,'${td_flag_params}'),1,0) AS td_flag ,
  COUNT(*) AS order_cnt ,
  SUM(total_amount) AS total_amount
FROM
  td_roi_order_analytics
GROUP BY
  1,2,3,4,5