WITH t0 AS (
  SELECT
    event_time_unix AS time , 
    event_time ,
    TD_SESSIONIZE(event_time_unix, ${session_span}, appsflyer_id) as session_id ,
    appsflyer_id ,
    CASE
      WHEN advertising_id is not NULL THEN advertising_id
      WHEN idfa is not NULL THEN idfa
      ELSE NULL
    END ifa ,
    CASE
      WHEN advertising_id is not NULL THEN 'Android'
      WHEN idfa is not NULL THEN 'iOS'
      ELSE NULL
    END ifa_type ,
    CASE
      WHEN android_id is not NULL THEN android_id
      WHEN idfv is not NULL THEN idfv
      ELSE NULL
    END mobile_id ,
    CASE
      WHEN android_id is not NULL THEN 'android_id'
      WHEN idfv is not NULL THEN 'idfv'
      ELSE NULL
    END mobile_id_type ,
    event_name ,
    event_value ,
    att ,
    af_ad ,
    af_ad_id ,
    af_ad_type ,
    af_adset ,
    af_attribution_lookback,
    af_c_id,
    af_cost_model,
    af_cost_value,
    af_keywords ,
    af_prt ,
    af_reengagement_window ,
    af_siteid ,
    af_sub_siteid ,
    af_sub1 ,
    af_sub2 ,
    af_sub3 ,
    af_sub4 ,
    af_sub5 ,
    amazon_aid,
    api_version ,
    attributed_touch_time ,
    attributed_touch_time_selected_timezone,
    attributed_touch_type,
    campaign ,
    campaign_type,
    carrier ,
    city ,
    contributor_1_campaign ,
    contributor_1_match_type,
    contributor_1_media_source ,
    contributor_1_touch_time ,
    contributor_1_touch_type ,
    contributor_2_af_prt,
    contributor_2_campaign ,
    contributor_2_match_type ,
    contributor_2_media_source ,
    contributor_2_touch_time ,
    contributor_2_touch_type,
    contributor_3_af_prt,
    contributor_3_campaign ,
    contributor_3_match_type ,
    contributor_3_media_source ,
    contributor_3_touch_time ,
    contributor_3_touch_type,
    conversion_type ,
    custom_data,
    custom_dimension ,
    deeplink_url ,
    device_model ,
    dma ,
    event_revenue ,
    event_revenue_currency ,
    event_revenue_usd ,
    gp_broadcast_referrer ,
    gp_referrer,
    http_referrer ,
    imei ,
    install_app_store ,
    install_time ,
    ip AS td_ip ,
    is_receipt_validated ,
    is_retargeting ,
    keyword_id ,
    keyword_match_type,
    network_account_id ,
    operator,
    original_url ,
    platform ,
    postal_code,
    retargeting_conversion_type ,
    revenue_in_selected_currency ,
    state ,
    store_reinstall ,
    TD_TIME_PARSE(install_time,'JST') AS unix_install_time ,
    user_agent AS td_user_agent
    ${(Object.prototype.toString.call(media[params].json_columns) === '[object Array]')?','+media[params].json_columns.join():''}
  FROM (
    SELECT
      * ,
      TD_TIME_PARSE(event_time,'JST') AS event_time_unix
    FROM
      ${media[params].log_db}.${media[params].log_tbl}
    WHERE
      ${time_filter}
    DISTRIBUTE BY 
      appsflyer_id
    SORT BY 
      appsflyer_id,TD_TIME_PARSE(event_time,'JST')
    ) t
)

-- DIGDAG_INSERT_LINE
SELECT
  '${media[params].media_name}' AS media_name ,
  IF( user_id is NULL ,
    	MAX(user_id) OVER (PARTITION BY session_id) ,
    	user_id 
  ) AS user_id_comp ,
  row_number() over (partition by session_id order by time ASC) AS session_num ,
	parse_url(td_url ,'HOST') AS td_host ,
	parse_url(td_url ,'PATH') AS td_path ,
	parse_url(td_url,'QUERY','utm_campaign') as utm_campaign ,
	parse_url(td_url,'QUERY','utm_medium') as utm_medium ,
	parse_url(td_url,'QUERY','utm_source') as utm_source ,
	parse_url(td_url,'QUERY','utm_term') as utm_term ,
  TD_TIME_FORMAT(time,'yyyy-MM-dd HH:mm:ss','JST') AS access_date_time ,
  TD_TIME_FORMAT(time,'yyyy-MM-dd','JST') AS access_date ,
  TD_TIME_FORMAT(time,'HH','JST') AS access_hour ,
  TD_TIME_FORMAT(time,'ww','JST') AS week ,
  TD_TIME_FORMAT(time,'EEE','JST') AS dow ,
  TD_TIME_FORMAT(time,'a','JST') AS ampm ,
  MIN(time) OVER (PARTITION BY session_id) AS session_start_time ,
  MAX(time) OVER (PARTITION BY session_id) AS session_end_time ,
  * 
FROM
  t0