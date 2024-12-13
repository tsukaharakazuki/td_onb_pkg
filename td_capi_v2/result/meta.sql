WITH t0 AS (
  SELECT
    * ,
    ${brand[params].meta.custom_data} AS custom_data ,
    email AS em,
    phone_meta AS ph ,
    gender AS ge ,
    birth_date AS db ,
    first_name AS fn ,
    last_name AS ln ,
    city AS ct ,
    zip_code AS zp ,
    amount AS value ,
    url AS event_source_url ,
    user_agent AS client_user_agent ,
    ip AS client_ip_address 
  FROM 
    ${target_tbl}
)

SELECT
  'Purchase' AS event_name , --
  'website' AS action_source , --
  time AS event_time  --
  ${(Object.prototype.toString.call(result_params) === '[object Array]')?','+result_params.join():''}
FROM
  t0