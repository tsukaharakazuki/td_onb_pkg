SELECT
  td_ms_id ,
  td_ms_id_type ,
  COLLECT_SET(behavior_type) AS behavior_type ,
  MAX_BY(ifa, if(ifa is null,null,time)) AS ifa ,
  MAX_BY(ifa_type, if(ifa_type is null,null,time)) AS ifa_type ,
  MAX_BY(ifas, if(ifas is null,null,time)) AS ifas ,
  MAX_BY(td_cookie, if(td_cookie is null,null,time)) AS td_cookie ,
  MAX_BY(td_cookies, if(td_cookies is null,null,time)) AS td_cookies ,
  MAX_BY(td_client_id, if(td_client_id is null,null,time)) AS td_client_id ,
  MAX(user_id) AS user_id ,
  MAX(time) AS time
FROM 
  ${media[params].output_db}.ms_master_table_${media[params].media_name}
GROUP BY 
  1,2
