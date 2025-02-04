SELECT
  * ,
  '${segment_id}' AS segment_id ,
  '${segment_name}' AS segment_name ,
  '${proc_date}' AS proc_date ,
  TD_TIME_PARSE('${proc_date}','JST') AS proc_unixtime
FROM
  ${activation_actions_db}.${activation_actions_table}