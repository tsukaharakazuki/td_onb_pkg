SELECT
  behavior_type ,
  td_ms_id ,
  td_ms_id_type ,
  MAX_BY(ifa, if(ifa is null,null,time)) AS ifa ,
  MAX_BY(ifa_type, if(ifa_type is null,null,time)) AS ifa_type ,
  ARRAY_AGG(DISTINCT ifa) FILTER(WHERE ifa IS NOT NULL) AS ifas ,
  MAX_BY(td_cookie, if(td_cookie is null,null,time)) AS td_cookie ,
  MAX_BY(td_client_id, if(td_client_id is null,null,time)) AS td_client_id ,
  MAX(user_id_comp) FILTER(WHERE user_id_comp IS NOT NULL) AS user_id 
FROM 
  ${media[params].output_db}.ms_behavior_${media[params].media_name}
GROUP BY 
  1,2,3
