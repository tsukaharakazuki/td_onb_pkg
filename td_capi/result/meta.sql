WITH t0 AS (
  SELECT
    ${brand[params].meta.custom_data} AS custom_data ,
    *
  FROM (
    SELECT
      uid ,
      email AS em,
      phone_meta AS ph ,
      gender AS ge ,
      birth_date AS db ,
      first_name AS fn ,
      last_name AS ln ,
      prefecture ,
      city AS ct ,
      zip_code AS zp ,
      country ,
      currency 
    FROM
      capi_user
  ) a
  INNER JOIN (
    SELECT
      * ,
      amount AS value ,
      url AS event_source_url ,
      user_agent AS client_user_agent ,
      ip AS client_ip_address 
    FROM
      capi_online_${brand[params].name} 
  ) b
  ON
    a.uid = b.uid
)

SELECT
  'Purchase' AS event_name , --
  'website' AS action_source , --
  time AS event_time  --
  ${(Object.prototype.toString.call(result_params) === '[object Array]')?','+result_params.join():''}
FROM
  t0