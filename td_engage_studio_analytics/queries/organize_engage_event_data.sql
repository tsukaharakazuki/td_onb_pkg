SELECT
  custom_event_id,
  message_id,
  email_message_id ,
  to ,
  "from" ,
  REGEXP_EXTRACT("from",'[a-zA-Z0-9_.+-]+@([a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.)+[a-zA-Z]{2,}') AS from_email ,
  subject ,
  bounce_type,
  event_type,
  TD_TIME_PARSE(COALESCE(open_timestamp, bounce_timestamp, delivery_timestamp, timestamp)) AS event_timestamp
FROM 
  ${engage_databse}.${engage_event_table}