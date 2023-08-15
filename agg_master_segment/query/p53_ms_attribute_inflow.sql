SELECT
  *
FROM (
  SELECT
    td_ms_id ,
    inflow_source_medium ,
    inflow_source ,
    inflow_medium ,
    inflow ,
    last_infrow_unix ,
    RANK() OVER (PARTITION BY td_ms_id ORDER BY inflow DESC) AS rnk
  FROM
    ${media[params].output_db}.calc_inflow_${media[params].media_name}
)
WHERE
  rnk <= 5