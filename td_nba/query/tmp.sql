SELECT
  * 
FROM (
  SELECT
    * 
  FROM
    ${td.database}.nba_user
    --${list[param].output_db}.nba_user_${list[param].list_name}
  WHERE
    inflow_rank < ${inflow.max_rank}
) a
LEFT JOIN (
  SELECT
    td_source_medium ,
    cv_rank
  FROM
    ${list[param].output_db}.nba_cv_${list[param].list_name}
  WHERE
    cv_rank < ${inflow.max_rank}
) b
ON
  a.inflow_source_medium = b.td_source_medium

