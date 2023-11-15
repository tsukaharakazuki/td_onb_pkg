SELECT
  behavior_type ,
  td_ms_id,
  td_ms_id_type ,
  MAX(user_id_comp) FILTER(WHERE user_id_comp IS NOT NULL) AS user_id ,
  MAX_BY(td_cookie, if(td_cookie is null,null,time)) AS td_cookie ,
  ARRAY_AGG(DISTINCT td_cookie) FILTER(WHERE td_cookie IS NOT NULL) AS td_cookies ,
  MAX_BY(td_client_id, if(td_client_id is null,null,time)) AS td_client_id 
FROM 
  ${media[params].output_db}.ms_behavior_${media[params].media_name}
GROUP BY 
  1,2,3
