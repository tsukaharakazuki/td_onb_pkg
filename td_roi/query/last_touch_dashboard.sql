SELECT
  TD_TIME_FORMAT(time_purchace,'yyyy-MM-dd','JST') AS purchace_date ,
  TD_TIME_FORMAT(time_purchace,'yyyy-MM','JST') AS purchace_month ,
  TD_TIME_FORMAT(time_purchace,'yyyy','JST') AS purchace_year ,
  td_source ,
  td_medium ,
  td_campaign ,
  td_smc 
  ${(Object.prototype.toString.call(resurl_add_col) === '[object Array]')?','+resurl_add_col.join():''}
  , SUM(amount) AS amount_total ,
  COUNT(DISTINCT user_id) AS uu_date
FROM
  roi_last_touch_yesterday
GROUP BY
  time_purchace ,
  td_source ,
  td_medium ,
  td_campaign ,
  td_smc
  ${(Object.prototype.toString.call(resurl_add_col) === '[object Array]')?','+resurl_add_col.join():''}
