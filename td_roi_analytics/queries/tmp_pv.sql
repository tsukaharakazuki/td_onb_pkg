SELECT
  session_id ,
  td_cookie ,
  a.time ,
  session_start_time ,
  ${user_id} AS user_id ,
  td_host ,
  td_path ,
  IF(REGEXP_LIKE(td_url ,'${conversion_urls.join("|")}'),${web_order_id},NULL) AS td_order_id ,
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
  END td_source_medium ,
  utm_campaign AS td_campaign
FROM (
  SELECT
    *
  FROM
    ${weblog_db}.${weblog_tbl}
  WHERE
    td_data_type = 'pageview'
    ${span}
) a
INNER JOIN
  td_sandbox.td_roi_cv_session b
ON
  a.session_id = b.cv_session_id