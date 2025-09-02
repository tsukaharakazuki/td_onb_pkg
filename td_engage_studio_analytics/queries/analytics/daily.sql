SELECT
  custom_event_id ,
  from_email ,
  email_message_id ,
  TD_TIME_FORMAT(event_timestamp,'yyyy-MM-dd','JST') AS date ,
  event_type ,
  COUNT(DISTINCT message_id) AS cnt ,
  COUNT(DISTINCT to) AS cnt_actual 
FROM
  organize_engage_event_data
GROUP BY
  1,2,3,4,5