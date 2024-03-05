WITH t0 AS (
  SELECT
    *
  FROM (
    SELECT
      uid ,
      email AS hashed_email ,
      phone_e164 AS hashed_phone_number ,
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
      CAST(amount AS INT) AS yahoo_ydn_conv_value 
    FROM
      capi_online_${brand[params].name} 
  ) b
  ON
    a.uid = b.uid
)

SELECT
  '${brand[params].yahoo.yahoo_ydn_conv_io}' AS yahoo_ydn_conv_io ,
  '${brand[params].yahoo.yahoo_ydn_conv_label}' AS yahoo_ydn_conv_label ,
  time AS event_time 
  ${(Object.prototype.toString.call(result_params) === '[object Array]')?','+result_params.join():''}
FROM
  t0
