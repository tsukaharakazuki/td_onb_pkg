SELECT
  behavior_type ,
  td_ms_id ,
  MAX_BY(td_cookie, time) AS td_cookie ,
  MAX_BY(td_client_id, time) AS td_client_id , 
  MAX_BY(user_id, time) AS user_id 
FROM 
  ${media[params].output_db}.ms_behavior_${media[params].media_name}
GROUP BY 
  1,2,3
