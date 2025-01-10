WITH t0 AS (
  SELECT
    * ,
    NULL AS na
  FROM
    ${brand[params].pos.db}.${brand[params].pos.tbl}
  WHERE
    TD_INTERVAL(time,'-${regular_span}','JST')
)

SELECT
  ${brand[params].pos.user_id} AS uid ,
  '${brand[params].pos.url}' AS url ,
  '${brand[params].pos.ip}' AS ip ,
  '${brand[params].pos.user_agent}' AS user_agent ,
  '${brand[params].pos.title}' AS title ,
  IF(${brand[params].pos.order_id} is not NULL ,${brand[params].pos.order_id},CAST(NULL AS VARCHAR)) AS order_id ,
  ${brand[params].pos.amount} AS amount ,
  IF(
    REGEXP_LIKE(CAST(${brand[params].pos.order_date_time} AS VARCHAR),'^\d$') ,
    CAST(${brand[params].pos.order_date_time} AS BIGINT) ,
    TD_TIME_PARSE(${brand[params].pos.order_date_time},'JST')
  ) AS time
FROM
  t0
