WITH t0 AS (
  SELECT
    *
  FROM (
    SELECT
      SPLIT(REGEXP_REPLACE(${brand[params].online.datalayer_ec_items},'^\[\{|\}\]$',''),'},{') AS tmp_val ,
      *
    FROM (
      SELECT
        * ,
        NULL AS na
      FROM
        ${brand[params].online.db}.${brand[params].online.tbl}
      WHERE
        true
        AND TD_INTERVAL(time,'-${regular_span}d','JST')
    )
    WHERE
      true
      AND REGEXP_LIKE(
        ${brand[params].online.url},
        '${(Object.prototype.toString.call(brand[params].online.cnv_url) === '[object Array]')?brand[params].online.cnv_url.join('|'):''}'
      )
  )
  CROSS JOIN 
    UNNEST(tmp_val) AS t(ec_datalayer)
)

SELECT
  ${brand[params].online.user_id} AS uid ,
  ${brand[params].online.url} AS url ,
  ${brand[params].online.referrer} AS referrer ,
  IF(REGEXP_LIKE(${brand[params].online.ip},'^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$'),${brand[params].online.ip},NULL) AS ip ,
  ${brand[params].online.user_agent} AS user_agent ,
  ${brand[params].online.title} AS title ,
  url_extract_parameter(${brand[params].online.url}, 'gclid') AS gclid ,
  url_extract_parameter(${brand[params].online.url}, 'ldtag_cl') AS ldtag_cl ,
  IF('${brand[params].online.fbp}' <> 'na',${brand[params].online.fbp},CAST(NULL AS VARCHAR)) AS fbp ,
  IF('${brand[params].online.fbc}' <> 'na',${brand[params].online.fbc},CAST(NULL AS VARCHAR)) AS fbc ,
  IF('${brand[params].online.yclid}' <> 'na',${brand[params].online.yclid},CAST(NULL AS VARCHAR)) AS yclid ,
  IF('${brand[params].online.yjr_yjad}' <> 'na',${brand[params].online.yjr_yjad},CAST(NULL AS VARCHAR)) AS yjr_yjad ,
  IF('${brand[params].online.lt_cid}' <> 'na',${brand[params].online.lt_cid},CAST(NULL AS VARCHAR)) AS lt_cid ,
  IF(${brand[params].online.order_id} is not NULL ,${brand[params].online.order_id},CAST(NULL AS VARCHAR)) AS order_id ,
  JSON_EXTRACT_SCALAR('{'||ec_datalayer||'}','$.item_name') AS item_name ,
  JSON_EXTRACT_SCALAR('{'||ec_datalayer||'}','$.item_id') AS item_id ,
  JSON_EXTRACT_SCALAR('{'||ec_datalayer||'}','$.price') AS price ,
  JSON_EXTRACT_SCALAR('{'||ec_datalayer||'}','$.item_category') AS item_category ,
  JSON_EXTRACT_SCALAR('{'||ec_datalayer||'}','$.quantity') AS quantity ,
  CAST(JSON_EXTRACT_SCALAR('{'||ec_datalayer||'}','$.price') AS BIGINT) 
    * CAST(JSON_EXTRACT_SCALAR('{'||ec_datalayer||'}','$.quantity') AS BIGINT) AS amount ,
  time
FROM
  t0
