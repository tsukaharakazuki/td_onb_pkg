WITH t1 AS (
  SELECT
    time ,
    td_data_type ,
    TD_SESSIONIZE_WINDOW(time, ${session_span}) OVER (PARTITION BY cookie ORDER BY time) AS session_id ,
    cookie ,
    cookie_type ,
    td_client_id ,
    td_global_id ,
    td_ssc_id ,
    user_id ,
    utm_campaign ,
    utm_medium ,
    utm_source ,
    utm_term ,
    CASE
      WHEN utm_source is not NULL AND utm_medium is not NULL
        THEN utm_source||'/'||utm_medium
      WHEN utm_source is not NULL AND utm_medium is NULL
        THEN utm_source||'/(none)'
      WHEN utm_source is NULL AND utm_medium is not NULL
        THEN '(none)/'||utm_medium
      WHEN REGEXP_LIKE(td_url, 'gclid')
        THEN 'google/cpc'   
      WHEN REGEXP_LIKE(td_url, 'fbclid')
        THEN 'facebook/ad'   
      WHEN REGEXP_LIKE(td_url, 'yclid')
        THEN 'yahoo/ad'   
      WHEN REGEXP_LIKE(td_url, 'ldtag_cl')
        THEN 'line/ad'   
      WHEN REGEXP_LIKE(td_url, 'twclid')
        THEN 'x/ad'   
      WHEN REGEXP_LIKE(td_url, 'ttclid')
        THEN 'tiktok/ad'   
      WHEN td_ref_host = '' OR td_ref_host = td_host OR td_ref_host is NULL
        THEN '(direct)/(none)'
      WHEN REGEXP_LIKE(td_ref_host, '(mail)\.(google|yahoo|nifty|excite|ocn|odn|jimdo)\.')
        THEN CONCAT(REGEXP_EXTRACT(td_ref_host, '(mail)\.(google|yahoo|nifty|excite|ocn|odn|jimdo)\.', 2), '/mail')
      WHEN REGEXP_LIKE(td_ref_host, '^outlook.live.com$')
        THEN 'outlook/mail'
      WHEN REGEXP_LIKE(td_ref_host, '\.*(facebook|instagram|line|ameblo)\.')
        THEN CONCAT(REGEXP_EXTRACT(td_ref_host, '\.*(facebook|instagram|line|ameblo)\.', 1), '/social')
      WHEN REGEXP_LIKE(td_ref_host, '^t.co$')
        THEN 'twitter/social'
      WHEN REGEXP_LIKE(td_ref_host, '\.(criteo|outbrain)\.')
        THEN CONCAT(REGEXP_EXTRACT(td_ref_host, '\.(criteo|outbrain)\.', 1), '/display')
      WHEN REGEXP_LIKE(td_ref_host, '(search)*\.*(google|yahoo|biglobe|nifty|goo|so-net|livedoor|rakuten|auone|docomo|naver|hao123|myway|dolphin-browser|fenrir|norton|uqmobile|net-lavi|newsplus|jword|ask|myjcom|1and1|excite|mysearch|kensakuplus)\.')
        THEN CONCAT(REGEXP_EXTRACT(td_ref_host, '(search)*\.*(google|yahoo|biglobe|nifty|goo|so-net|livedoor|rakuten|auone|docomo|naver|hao123|myway|dolphin-browser|fenrir|norton|uqmobile|net-lavi|newsplus|jword|ask|myjcom|1and1|excite|mysearch|kensakuplus)\.', 2), '/organic')
      WHEN td_ref_host = 'kids.yahoo.co.jp' AND SPLIT_PART(URL_EXTRACT_PATH(td_referrer), '/', 2) = 'search' THEN 'yahoo/organic'
      ELSE CONCAT(td_ref_host, '/referral')
    END source_medium ,
    td_referrer ,
    td_ref_host ,
    td_url ,
    td_host ,
    td_path ,
    td_title ,
    td_description ,
    td_ip ,
    td_os ,
    td_user_agent ,
    td_browser ,
    td_screen ,
    td_viewport , 
    ua_os ,
    ua_vendor ,
    ua_os_version ,
    ua_browser ,
    ua_category ,
    ip_country ,
    ip_prefectures ,
    ip_city 
    ${(Object.prototype.toString.call(media[params].all_columns.columns) === '[object Array]')?','+media[params].all_columns.columns.join():''}
  FROM
    tmp_agg_weblog_regular
)


SELECT
  time ,
  '${media[params].media_name}' AS media_name ,
  td_data_type ,
  TD_TIME_FORMAT(time,'yyyy-MM-dd HH:mm:ss','JST') AS access_date_time ,
  TD_TIME_FORMAT(time,'yyyy-MM-dd','JST') AS access_date ,
  TD_TIME_FORMAT(time,'HH','JST') AS access_hour ,
  TD_TIME_FORMAT(time,'ww','JST') AS week ,
  TD_TIME_FORMAT(time,'EEE','JST') AS dow ,
  TD_TIME_FORMAT(time,'a','JST') AS ampm ,
  MIN(time) OVER (PARTITION BY session_id) AS session_start_time ,
  MAX(time) OVER (PARTITION BY session_id) AS session_end_time ,
  session_id ,
  row_number() over (partition by session_id order by time ASC) AS session_num ,
  LEAD(time) OVER (PARTITION BY session_id order by time ASC) - MIN(time) OVER (PARTITION BY session_id,td_path order by time ASC) AS browsing_sec ,
  --LEAD(time) OVER (PARTITION BY session_id order by time ASC) - time AS browsing_sec ,
  cookie AS td_cookie ,
  cookie_type AS td_cookie_type ,
  td_client_id ,
  td_global_id ,
  td_ssc_id ,
  user_id ,
  IF( user_id is NULL ,
    	MAX(user_id) OVER (PARTITION BY session_id) ,
    	user_id 
  ) AS user_id_comp ,
  utm_campaign ,
  utm_medium ,
  utm_source ,
  utm_term ,
  source_medium AS td_source_medium ,
  SPLIT(source_medium, '/')[1] AS td_source ,
  SPLIT(source_medium, '/')[2] AS td_medium ,
  td_referrer ,
  td_ref_host ,
  td_url ,
  td_host||td_path AS article_key ,
  td_host ,
  td_path ,
  td_title ,
  td_description ,
  td_ip ,
  td_os ,
  td_user_agent ,
  td_browser ,
  td_screen ,
  td_viewport ,
  ua_os ,
  ua_vendor ,
  ua_os_version ,
  ua_browser ,
  ua_category ,
  ip_country ,
  REGEXP_REPLACE(REGEXP_REPLACE(ip_prefectures, '^Ō', 'O'), 'ō', 'o') AS ip_prefectures ,
  REGEXP_REPLACE(REGEXP_REPLACE(ip_city, '^Ō', 'O'), 'ō', 'o') AS ip_city ,
  CAST(TO_UNIXTIME(NOW()) AS BIGINT)AS td_proc_date 
  ${(Object.prototype.toString.call(media[params].all_columns.columns) === '[object Array]')?','+media[params].all_columns.columns.join():''}
  ${(Object.prototype.toString.call(media[params].all_first_regular_other_process.regular) === '[object Array]')?','+media[params].all_first_regular_other_process.regular.join():''}
FROM
  t1
