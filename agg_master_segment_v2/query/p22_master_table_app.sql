SELECT
  behavior_type ,
  td_ms_id ,
  MAX_BY(ifa, if(ifa is null,null,time)) AS ifa ,
  MAX_BY(ifa_type, if(ifa_type is null,null,time)) AS ifa_type ,
  COLLECT_SET(ifa) AS ifas , 
  MAX_BY(user_id, time) AS user_id ,
  MAX(time) AS time
FROM 
  ${media[params].output_db}.ms_behavior_${media[params].media_name}
GROUP BY 
  1,2
