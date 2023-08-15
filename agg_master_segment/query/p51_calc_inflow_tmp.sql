WITH t0 AS (
  SELECT
    td_ms_id ,
    td_source_medium ,
    td_source ,
    td_medium ,
    time
  FROM
    ${media[params].output_db}.ms_behavior_${media[params].media_name}
  WHERE
    TD_INTERVAL(time, '-${log_span}/now', 'JST')
    AND session_num = 1
)

SELECT
  td_ms_id ,
  td_source_medium AS inflow_source_medium ,
  td_source AS inflow_source ,
  td_medium AS inflow_medium ,
  COUNT(*) AS inflow ,
  MAX(time) AS last_infrow_unix
FROM
  t0
GROUP BY
  1,2,3,4