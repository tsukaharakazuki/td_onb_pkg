SELECT
  TD_TIME_FORMAT(time,'yyyy/MM/dd','JST') AS date ,
  td_source_${flag} AS td_source ,
  td_medium_${flag} AS td_medium_ ,
  td_campaign_${flag} AS td_campaign ,
  IF(REGEXP_LIKE(td_campaign_${flag},'${td_flag_params}'),1,0) AS td_flag ,
  COUNT(*) AS order_cnt ,
  SUM(total_amount) AS total_amount
FROM
  td_roi_order_analytics
GROUP BY
  1,2,3,4,5
