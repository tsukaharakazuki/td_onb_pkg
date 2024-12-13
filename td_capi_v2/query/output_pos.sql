SELECT
  a.* ,
  b.url ,
  b.ip ,
  b.user_agent ,
  b.title ,
  b.order_id ,
  b.amount ,
  b.time
FROM (
  SELECT
    uid ,
    email ,
    phone_meta ,
    phone_e164 ,
    gender ,
    birth_date ,
    first_name ,
    last_name ,
    prefecture ,
    city ,
    zip_code ,
    country ,
    currency ,
    ifa ,
    line_uid 
  FROM
    capi_user
) a
INNER JOIN (
  SELECT
    * 
  FROM
    ${target_tbl}
  WHERE
    TD_INTERVAL(time,'-${regular_span}d','JST')
) b
ON
  a.uid = b.uid
