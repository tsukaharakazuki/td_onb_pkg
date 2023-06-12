SELECT
	time ,
	'read' AS td_data_type ,
	IF(${media[params].primary_cookie} is NULL OR ${media[params].primary_cookie} = '' , ${media[params].sub_cookie}, ${media[params].primary_cookie}) AS cookie ,
	IF(${media[params].primary_cookie} is NULL OR ${media[params].primary_cookie} = '' , '${media[params].sub_cookie}', '${media[params].primary_cookie}') AS cookie_type ,
	td_client_id ,
	td_global_id ,
	${media[params].td_ssc_id_read} AS td_ssc_id ,
	${media[params].user_id_read} AS user_id ,
	url_extract_parameter(td_url, 'utm_campaign') AS utm_campaign ,
	url_extract_parameter(td_url, 'utm_medium') AS utm_medium ,
	url_extract_parameter(td_url, 'utm_source') AS utm_source ,
	url_extract_parameter(td_url, 'utm_term') AS utm_term , 
	td_referrer ,
	url_extract_host(td_referrer) AS td_ref_host ,
	td_url ,
	url_extract_host(td_url) AS td_host ,
	url_extract_path(td_url) AS td_path ,
	td_title ,
	td_description ,
	td_ip ,
	td_os ,
	td_user_agent ,
	td_browser ,
	td_screen ,
	td_viewport , 
	element_at(TD_PARSE_AGENT(td_user_agent), 'os') AS os ,
	element_at(TD_PARSE_AGENT(td_user_agent), 'vendor') AS vendor ,
	element_at(TD_PARSE_AGENT(td_user_agent), 'os_version') AS os_version ,
	element_at(TD_PARSE_AGENT(td_user_agent), 'name') AS browser ,
	element_at(TD_PARSE_AGENT(td_user_agent), 'category') AS category ,
	TD_IP_TO_COUNTRY_NAME(td_ip) AS country ,
	TD_IP_TO_LEAST_SPECIFIC_SUBDIVISION_NAME(td_ip) AS prefectures ,
	TD_IP_TO_CITY_NAME(td_ip) AS city ,
	${media[params].read_col} AS read
	${(Object.prototype.toString.call(media[params].read_columns.columns) === '[object Array]')?','+media[params].read_columns.columns.join():''}
	${(Object.prototype.toString.call(media[params].read_first_regular_other_process.regular) === '[object Array]')?','+media[params].read_first_regular_other_process.regular.join():''}
FROM
	${media[params].read_db}.${media[params].read_tbl}
WHERE
	TD_INTERVAL(time, '-${regular_span}', 'JST') AND
	TD_PARSE_AGENT(td_user_agent) ['category'] <> 'crawler' AND
	td_client_id != '00000000-0000-4000-8000-000000000000' AND
	NOT regexp_like(td_browser, '^(?:Googlebot(?:-.*)?|BingPreview|bingbot|YandexBot|PingdomBot)$') AND
	td_host != 'gtm-msr.appspot.com' AND
	td_client_id is not NULL AND
	td_client_id <> 'undefined'
