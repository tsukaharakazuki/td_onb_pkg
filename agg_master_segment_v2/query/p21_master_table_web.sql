SELECT
  behavior_type ,
  td_ms_id,
  td_ms_id_type ,
  MAX(user_id_comp) AS user_id ,
  MAX_BY(td_cookie, if(td_cookie is null,null,time)) AS td_cookie ,
  COLLECT_SET(td_cookie) AS td_cookies ,
  MAX_BY(td_client_id, if(td_client_id is null,null,time)) AS td_client_id ,
  MAX(time) AS time
FROM 
  ${media[params].output_db}.ms_behavior_${media[params].media_name}
GROUP BY 
  1,2,3
