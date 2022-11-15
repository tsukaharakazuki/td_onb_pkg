SELECT
  behavior_type ,
  td_ms_id ,
  MAX_BY(ifa, time) AS ifa ,
  MAX_BY(ifa_type, time) AS ifa_type ,
  ARRAY_AGG(DISTINCT ifa) FILTER(WHERE ifa IS NOT NULL) AS ifas 
  --, MAX_BY(user_id, time) AS user_id ,
  --ARRAY_AGG(DISTINCT user_id) FILTER(WHERE user_id IS NOT NULL) AS user_ids 
FROM 
  ${media[params].output_db}.ms_behavior_${media[params].media_name}
GROUP BY 
  1,2
