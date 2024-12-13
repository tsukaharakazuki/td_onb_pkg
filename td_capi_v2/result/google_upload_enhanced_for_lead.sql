WITH t0 AS (
  SELECT
    * ,
    phone_e164 AS phone_number ,
    gender AS ge ,
    birth_date AS db ,
    first_name AS first_name ,
    last_name AS last_name ,
    city AS street_address ,
    zip_code AS postal_code ,
    currency AS currency_code ,
    CAST(amount AS DOUBLE) AS conversion_value ,
    'UNSPECIFIED' AS conversion_environment
  FROM 
    ${target_tbl}
)

SELECT
  TD_TIME_FORMAT(time,'yyyy-MM-dd HH:mm:ss+09:00') AS conversion_date_time ,
  '${brand[params].google.conversion_action_id}' as conversion_action_id ,
  conversion_value ,
  currency_code 
  ${(Object.prototype.toString.call(result_params) === '[object Array]')?','+result_params.join():''}
FROM
  t0
