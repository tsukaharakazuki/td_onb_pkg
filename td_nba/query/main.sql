WITH t0 AS (
  SELECT
    td_ms_id ,
    MIN_BY(td_source_medium,cv_rank) AS best_source_medium ,
    MIN_BY(inflow_source_medium,inflow_rank) AS next_most_action 
  FROM
    ${list[param].output_db}.nba_tmp_${list[param].list_name}
  GROUP BY 
    1
)

, t1 AS (
SELECT
  td_ms_id ,
  next_most_action ,
  IF(best_source_medium is not NULL ,best_source_medium,best_action) AS next_best_action ,
  best_action AS next_better_action ,
  '${list[param].target_brand}' AS segment_name
FROM
  t0 a
LEFT JOIN (
  SELECT
    MAX_BY(td_source_medium,cnt) AS best_action
  FROM
    ${list[param].output_db}.nba_cv_${list[param].list_name}
) b
ON
  1 = 1
)

SELECT
  * ,
  'NBA|next_most_action:'||next_most_action||' next_best_action:'||next_best_action AS td_url 
FROM
  t1
