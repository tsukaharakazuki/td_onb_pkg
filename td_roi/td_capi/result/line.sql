WITH t0 AS (
  SELECT
    *
  FROM (
    SELECT
      uid ,
      email  ,
      phone_e164 AS phone ,
      ifa ,
      line_uid ,
      gender AS ge ,
      birth_date AS db ,
      first_name AS first_name ,
      last_name AS last_name ,
      prefecture ,
      city AS street_address ,
      zip_code AS postal_code ,
      country ,
      currency AS currency_code
    FROM
      capi_user
  ) a
  INNER JOIN (
    SELECT
      * ,
      LOWER(TO_HEX(SHA256(TO_UTF8(order_id)))) AS deduplication_key ,
      ip AS ip_address ,
      lt_cid AS browser_id ,
      ldtag_cl AS click_id
    FROM
      capi_online_${brand[params].name} 
  ) b
  ON
    a.uid = b.uid
)

SELECT
  'conversion' AS event_type , --'page_view' or 'conversion'
  'web' AS source_type ,
  deduplication_key ,
  time AS event_timestamp 
  ${(Object.prototype.toString.call(result_params) === '[object Array]')?','+result_params.join():''}
FROM
  t0
