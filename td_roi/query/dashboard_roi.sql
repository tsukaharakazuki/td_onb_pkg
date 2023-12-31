SELECT
  TD_TIME_FORMAT(time_purchace,'yyyy-MM-dd','JST') AS purchace_date ,
  TD_TIME_FORMAT(time_purchace,'yyyy-MM','JST') AS purchace_month ,
  TD_TIME_FORMAT(time_purchace,'yyyy','JST') AS purchace_year ,
  td_source ,
  td_medium ,
  td_campaign ,
  td_smc ,
  SUM(amount_first_touch) AS amount_first_touch ,
  SUM(amount_last_touch) AS amount_last_touch ,
  SUM(amount_multi_touch) AS amount_multi_touch ,
  SUM(amount_multi_touch_split) AS amount_multi_touch_split
FROM
  dist_roi_yesterday
GROUP BY
  time_purchace ,
  td_source ,
  td_medium ,
  td_campaign ,
  td_smc