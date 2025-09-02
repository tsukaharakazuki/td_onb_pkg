SELECT
  "to" AS to_email ,
  message_id ,
  email_message_id ,
  subject ,
  custom_event_id ,
  MAX("from") AS sender ,
  MAX(from_email) AS from_email ,
  MAX(IF(event_type = 'Send',event_timestamp,NULL)) AS send_unix ,
  MAX(IF(event_type = 'Delivery',event_timestamp,NULL)) AS delivery_unix ,
  MAX(IF(event_type = 'Open',event_timestamp,NULL)) AS open_unix ,
  MAX(IF(event_type = 'Click',event_timestamp,NULL)) AS click_unix ,
  MAX(IF(event_type = 'DeliveryDelay',event_timestamp,NULL)) AS DeliveryDelay_unix ,
  MAX(IF(event_type = 'Bounce',event_timestamp,NULL)) AS bounce_unix ,
  MAX_BY(IF(event_type = 'Bounce' ,bounce_type,NULL),event_timestamp) AS bounce_type 
FROM
  organize_engage_event_data
GROUP BY
  1,2,3,4,5
