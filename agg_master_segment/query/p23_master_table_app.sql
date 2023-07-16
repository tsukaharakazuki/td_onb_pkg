SELECT
  behavior_type ,
  td_ms_id ,
  td_ms_id_type ,
  MAX_BY(ifa, if(ifa is null,null,time)) AS ifa ,
  MAX_BY(ifa_type, if(ifa_type is null,null,time)) AS ifa_type ,
  ARRAY_AGG(DISTINCT ifa) FILTER(WHERE ifa IS NOT NULL) AS ifas 
  --, MAX_BY(user_id, time) AS user_id ,
  --ARRAY_AGG(DISTINCT user_id) FILTER(WHERE user_id IS NOT NULL) AS user_ids 
FROM 
  ${media[params].output_db}.ms_behavior_${media[params].media_name}
GROUP BY 
  1,2
