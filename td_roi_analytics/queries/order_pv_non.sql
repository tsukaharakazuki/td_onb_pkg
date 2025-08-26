SELECT
  td_order_id ,
  session_id ,
  MIN_BY(td_cookie,time) AS td_cookie ,
  MIN_BY(session_start_time,time) AS session_start_time ,
  MIN_BY(user_id,time) AS user_id ,
  MIN_BY(td_host,time) AS td_host ,
  MIN_BY(td_path,time) AS td_path ,
  MIN_BY(td_source_medium,time) AS td_source_medium ,
  MIN_BY(td_campaign,time) AS td_campaign ,
  MIN(time) AS time
FROM
  td_roi_tmp_pv
WHERE
  td_order_id is not NULL
GROUP BY
  1,2