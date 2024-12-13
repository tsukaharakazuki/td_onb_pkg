WITH t0 AS (
  SELECT
    * ,
    email AS hashed_email ,
    phone_e164 AS hashed_phone_number ,
    gender AS ge ,
    birth_date AS db ,
    first_name AS first_name ,
    last_name AS last_name ,
    city AS street_address ,
    zip_code AS postal_code ,
    currency AS currency_code ,
    CAST(amount AS INT) AS yahoo_ydn_conv_value 
  FROM 
    ${target_tbl}
)

SELECT
  '${brand[params].yahoo.yahoo_ydn_conv_io}' AS yahoo_ydn_conv_io ,
  '${brand[params].yahoo.yahoo_ydn_conv_label}' AS yahoo_ydn_conv_label ,
  time AS event_time 
  ${(Object.prototype.toString.call(result_params) === '[object Array]')?','+result_params.join():''}
FROM
  t0
