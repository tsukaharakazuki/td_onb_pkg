WITH t0 AS (
  SELECT
    *
  FROM (
    SELECT
      uid ,
      email ,
      phone_e164 AS phone_number ,
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
      CAST(amount AS DOUBLE) AS conversion_value 
    FROM
      capi_online_${brand[params].name} 
  ) b
  ON
    a.uid = b.uid
)

SELECT
  TD_TIME_FORMAT(time,'yyyy-MM-dd HH:mm:ss+09:00') AS conversion_date_time ,
  '${google.conversion_action_id}' as conversion_action_id ,
  gclid ,
  conversion_value ,
  currency_code
  ${(Object.prototype.toString.call(result_params) === '[object Array]')?','+result_params.join():''}
FROM
  t0
