SELECT
  ${brand[params].online.user_id} AS uid ,
  ${brand[params].online.url} AS url ,
  ${brand[params].online.referrer} AS referrer ,
  ${brand[params].online.ip} AS ip ,
  ${brand[params].online.user_agent} AS user_agent ,
  ${brand[params].online.title} AS title ,
  url_extract_parameter(${brand[params].online.url}, 'gclid') AS gclid ,
  url_extract_parameter(${brand[params].online.url}, 'ldtag_cl') AS ldtag_cl ,
  IF('${brand[params].online.fbp}' <> 'na',${brand[params].online.fbp},CAST(NULL AS VARCHAR)) AS fbp ,
  IF('${brand[params].online.fbc}' <> 'na',${brand[params].online.fbc},CAST(NULL AS VARCHAR)) AS fbc ,
  IF('${brand[params].online.yclid}' <> 'na',${brand[params].online.yclid},CAST(NULL AS VARCHAR)) AS yclid ,
  IF('${brand[params].online.yjr_yjad}' <> 'na',${brand[params].online.yjr_yjad},CAST(NULL AS VARCHAR)) AS yjr_yjad ,
  IF('${brand[params].online.lt_cid}' <> 'na',${brand[params].online.lt_cid},CAST(NULL AS VARCHAR)) AS lt_cid ,
  IF('${brand[params].online.amount}' <> 'na',CAST(${brand[params].online.amount} AS VARCHAR),CAST(NULL AS VARCHAR)) AS amount ,
  IF(${brand[params].online.order_id} is not NULL ,${brand[params].online.order_id},CAST(NULL AS VARCHAR)) AS order_id ,
  MAX(time) AS time 
FROM (
  SELECT
    * ,
    NULL AS na
  FROM
    ${brand[params].online.db}.${brand[params].online.tbl}
)
WHERE
  TD_INTERVAL(time,'-${regular_span}','JST')
  AND ${brand[params].online.user_id} is not NULL
  AND REGEXP_LIKE(
    ${brand[params].online.url},
    '${(Object.prototype.toString.call(brand[params].online.cnv_url) === '[object Array]')?brand[params].online.cnv_url.join('|'):''}'
  )
GROUP BY
  1,2,3,4,5,6,7,8,9,10,11,12,13,14,15