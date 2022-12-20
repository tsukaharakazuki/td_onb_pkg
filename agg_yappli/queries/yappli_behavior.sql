WITH t0 AS (
  SELECT
    TD_TIME_PARSE(timestamp) AS time ,
    TD_SESSIONIZE_WINDOW(time, ${session_span}) OVER (PARTITION BY ${apps[params].key_id} ORDER BY TD_TIME_PARSE(timestamp)) AS session_id ,
    _id ,
    uuid ,
    IF(idfa is not NULL,idfa,aaid) AS ifa ,
    CASE
      WHEN idfa is not NULL THEN 'idfa'
      WHEN aaid is not NULL THEN 'aaid'
      ELSE NULL
    END ifa_type ,
    idfa ,
    aaid ,
    CASE
      WHEN REGEXP_LIKE(event_category, '^(プッシュ通知|通知履歴|フォトフレーム)$|STORE') THEN REPLACE(event_category, ' ','')
      WHEN CARDINALITY(SPLIT(screen_name,'＞')) > 1 THEN REPLACE(SPLIT_PART(screen_name,'＞',1), ' ','')
      WHEN REGEXP_LIKE(screen_name,'^ ＞') THEN '閲覧'
      ELSE screen_name
    END event_name , 
    CASE
      WHEN REGEXP_LIKE(event_category, '^(プッシュ通知|通知履歴|フォトフレーム)$|STORE') THEN REPLACE(event_action, ' ','')||' '||event_label
      WHEN CARDINALITY(SPLIT(screen_name,'＞')) > 1 THEN REPLACE(SPLIT_PART(screen_name,'＞',2), ' ','')
      WHEN REGEXP_LIKE(screen_name,'^ ＞') THEN REPLACE(SPLIT_PART(screen_name,'＞',2), ' ','')
    END event_name_sub ,
    screen_name ,
    screen_name_id ,
    source_screen_name ,
    source_screen_id ,
    event_category ,
    event_action ,
    event_label ,
    event_value ,
    timestamp ,
    os ,
    os_version ,
    application_version ,
    ip_address ,
    user_agent ,
    TD_PARSE_AGENT(user_agent)['category'] AS ua_category ,
    TD_IP_TO_COUNTRY_NAME(ip_address) AS ip_country ,
    TD_IP_TO_LEAST_SPECIFIC_SUBDIVISION_NAME(ip_address) AS ip_prefectures ,
    TD_IP_TO_CITY_NAME(ip_address) AS ip_city 
    ${(Object.prototype.toString.call(apps[params].set_columns.columns) === '[object Array]')?','+apps[params].set_columns.columns.join():''}
  FROM
    ${apps[params].in_db}.${apps[params].in_tbl}
  WHERE
    TD_INTERVAL(TD_TIME_PARSE(timestamp),'-1d','JST')
)

SELECT
  time ,
  TD_TIME_FORMAT(time,'yyyy-MM-dd HH:mm:ss','JST') AS access_date_time ,
  TD_TIME_FORMAT(time,'yyyy-MM-dd','JST') AS access_date ,
  TD_TIME_FORMAT(time,'HH','JST') AS access_hour ,
  TD_TIME_FORMAT(time,'ww','JST') AS week ,
  TD_TIME_FORMAT(time,'EEE','JST') AS dow ,
  TD_TIME_FORMAT(time,'a','JST') AS ampm ,  
  session_id ,
  row_number() over (partition by session_id order by time ASC) AS session_num ,
  MIN(time) OVER (PARTITION BY session_id) AS session_start_time ,
  MAX(time) OVER (PARTITION BY session_id) AS session_end_time ,
  _id ,
  uuid ,
  ifa ,
  ifa_type ,
  idfa ,
  aaid ,
  event_name , 
  event_name_sub ,
  screen_name ,
  CASE 
    WHEN REGEXP_LIKE(event_name_sub,'shop/g/g') THEN REGEXP_REPLACE(REGEXP_REPLACE(event_name_sub, '.+shop/g/g',''), '\?.+','')
  END product_code ,
  url_extract_parameter(event_name_sub,'order_id') AS order_id ,
  screen_name_id ,
  source_screen_name ,
  source_screen_id ,
  event_category ,
  event_action ,
  event_label ,
  event_value ,
  timestamp ,
  os ,
  os_version ,
  application_version ,
  ip_address AS td_ip ,
  user_agent AS td_user_agent ,
  ua_category ,
  ip_country ,
  REGEXP_REPLACE(REGEXP_REPLACE(ip_prefectures, '^Ō', 'O'), 'ō', 'o') AS ip_prefectures ,
  REGEXP_REPLACE(REGEXP_REPLACE(ip_city, '^Ō', 'O'), 'ō', 'o') AS ip_city 
  ${(Object.prototype.toString.call(apps[params].set_columns.columns) === '[object Array]')?','+apps[params].set_columns.columns.join():''}
  ${(Object.prototype.toString.call(apps[params].first_regular_other_process.regular) === '[object Array]')?','+apps[params].first_regular_other_process.regular.join():''}
FROM
  t0
