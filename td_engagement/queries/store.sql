SELECT
  ${td.last_results.set_columns} ,
  '${proc_date}' AS proc_date ,
  TD_TIME_PARSE('${proc_date}','JST') AS time
FROM
  td_engagement_score_${val.label}