SELECT
  TD_TIME_FORMAT(time_purchace,'yyyy-MM-dd','JST') AS purchace_date ,
  TD_TIME_FORMAT(time_purchace,'yyyy-MM','JST') AS purchace_month ,
  TD_TIME_FORMAT(time_purchace,'yyyy','JST') AS purchace_year ,
  td_source ,
  td_medium ,
  td_campaign ,
  td_smc ,
  SUM(amount) AS amount_total ,
  COUNT(DISTINCT user_id) AS uu_date
FROM
  roi_last_touch
GROUP BY
  time_purchace ,
  td_source ,
  td_medium ,
  td_campaign ,
  td_smc   