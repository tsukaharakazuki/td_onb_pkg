SELECT
  behavior_type ,
  td_cookie AS td_ms_id ,
  user_id ,
  MAX_BY(td_client_id, time) AS td_client_id 
  --, MAX_BY(user_id, time) AS user_id ,
  --ARRAY_AGG(DISTINCT user_id) FILTER(WHERE user_id IS NOT NULL) AS user_ids 
FROM 
  ${media[params].output_db}.ms_behavior_${media[params].media_name}
GROUP BY 
  1,2,3
