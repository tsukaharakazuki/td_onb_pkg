SELECT
  custom_event_id ,
  from_email ,
  email_message_id ,
  subject,
  campaign_name,
  COUNT(DISTINCT CASE WHEN send_unix is not NULL THEN message_id END) AS send ,
  COUNT(DISTINCT CASE WHEN send_unix is not NULL THEN to_email END) AS send_actual ,
  COUNT(DISTINCT CASE WHEN delivery_unix is not NULL THEN message_id END) AS delivery ,
  COUNT(DISTINCT CASE WHEN delivery_unix is not NULL THEN to_email END) AS delivery_actual ,
  COUNT(DISTINCT CASE WHEN open_unix is not NULL THEN message_id END) AS open ,
  COUNT(DISTINCT CASE WHEN open_unix is not NULL THEN to_email END) AS open_actual ,
  COUNT(DISTINCT CASE WHEN click_unix is not NULL THEN message_id END) AS click ,
  COUNT(DISTINCT CASE WHEN click_unix is not NULL THEN to_email END) AS click_actual ,
  COUNT(DISTINCT CASE WHEN bounce_unix is not NULL THEN message_id END) AS bounce ,
  COUNT(DISTINCT CASE WHEN bounce_unix is not NULL THEN to_email END) AS bounce_actual ,
  CAST(ROUND((COUNT(CASE WHEN open_unix is not NULL THEN to_email END) * 100.0 / NULLIF(COUNT(CASE WHEN send_unix is not NULL THEN to_email END), 0)), 2) AS DOUBLE) AS pct_opened,
  COUNT(DISTINCT CASE WHEN click_unix is not NULL THEN to_email END) AS clicked_people,
  CAST(ROUND((COUNT(DISTINCT CASE WHEN click_unix is not NULL THEN to_email END) * 100.0 / NULLIF(COUNT(CASE WHEN send_unix is not NULL THEN to_email END), 0)), 2) AS DOUBLE) AS pct_clicked,
  CAST(ROUND((COUNT(DISTINCT CASE WHEN click_unix is not NULL THEN to_email END) * 100.0 / NULLIF(COUNT(DISTINCT CASE WHEN open_unix is not NULL THEN to_email END), 0)), 2) AS DOUBLE) AS clicked_to_open
FROM
  agg_engage_event_data
GROUP BY
  1,2,3,4,5
