SELECT
  name ,
  result_connection ,
  advertiser_id
FROM
  push_segment
WHERE
  TD_INTERVAL(time,'1d','JST')
  AND id <> 'NULL'
GROUP BY
  name ,
  result_connection ,
  advertiser_id