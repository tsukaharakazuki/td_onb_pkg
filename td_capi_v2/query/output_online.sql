SELECT
  a.* ,
  b.url ,
  b.referrer ,
  b.ip ,
  b.user_agent ,
  b.title ,
  b.gclid ,
  b.ldtag_cl ,
  b.fbp ,
  b.fbc ,
  b.yclid ,
  b.yjr_yjad ,
  b.lt_cid ,
  b.order_id ,
  b.item_name ,
  b.item_id ,
  b.price ,
  b.item_category ,
  b.quantity ,
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
