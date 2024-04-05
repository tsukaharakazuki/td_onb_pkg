SELECT
  td_ms_id ,
  inflow_source_medium ,
  inflow_source ,
  inflow_medium ,
  SUM(inflow) AS inflow ,
  MAX(time) AS last_infrow_unix
FROM
  ${media[params].output_db}.tmp_calc_inflow_${media[params].media_name}
GROUP BY
  1,2,3,4