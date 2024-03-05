SELECT
  IF('${brand[params].offline.user_id}' <> 'na',${brand[params].offline.user_id},CAST(NULL AS VARCHAR)) AS uid ,
  IF('${brand[params].offline.amount}' <> 'na',CAST(${brand[params].offline.amount} AS VARCHAR),CAST(NULL AS VARCHAR)) AS amount ,
  IF('${brand[params].offline.product}' <> 'na',${brand[params].offline.product},CAST(NULL AS VARCHAR)) AS product ,
  IF('${brand[params].offline.order_id}' <> 'na',${brand[params].offline.order_id},CAST(NULL AS VARCHAR)) AS order_id ,
  CASE
    WHEN REGEXP_LIKE(CAST(${brand[params].offline.order_time_unix} AS VARCHAR),'^\d+$')
      THEN CAST(${brand[params].offline.order_time_unix} AS INT)
    ELSE TD_TIME_PARSE(${brand[params].offline.order_time_unix},'JST')
  END order_time_unix ,
  CASE
    WHEN REGEXP_LIKE(CAST(${brand[params].offline.order_time_unix} AS VARCHAR),'^\d+$')
      THEN CAST(${brand[params].offline.order_time_unix} AS INT)
    ELSE TD_TIME_PARSE(${brand[params].offline.order_time_unix},'JST')
  END time
FROM (
  SELECT
    * ,
    NULL AS na
  FROM
    ${brand[params].offline.db}.${brand[params].offline.tbl}
)
WHERE
  TD_INTERVAL(${brand[params].offline.time_filter},'-${regular_span}','JST')
  ${(Object.prototype.toString.call(brand[params].offline.cnv_config) === '[object Array]')?'AND '+brand[params].offline.cnv_config.join(' AND '):''}