WITH t0 AS (
  SELECT
    TD_SESSIONIZE_WINDOW(time, (60*60*24*${roi_judge_date})) OVER (PARTITION BY ${pos.sessionize_col} ORDER BY time_inflow) AS p_session_id ,
    *
  FROM
    roi_behabior_purchace_yesterday
)

, t1 AS (
  SELECT
    ROW_NUMBER() OVER (PARTITION BY p_session_id ORDER BY time_inflow ASC) AS first_touch ,
    ROW_NUMBER() OVER (PARTITION BY p_session_id ORDER BY time_inflow DESC) AS last_touch ,
    1 AS multi_touch ,
    1.0 / (COUNT(*) OVER (PARTITION BY p_session_id)) AS multi_touch_split ,
    *
  FROM
    t0
)

SELECT
  amount * IF(first_touch = 1,first_touch,NULL) AS amount_first_touch ,
  amount * IF(last_touch = 1,last_touch,NULL) AS amount_last_touch ,
  amount * multi_touch AS amount_multi_touch ,
  amount * multi_touch_split AS amount_multi_touch_split ,
  *
FROM  
  t1