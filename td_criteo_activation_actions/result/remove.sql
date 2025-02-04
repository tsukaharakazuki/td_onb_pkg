SELECT
  userid ,
  name ,
  'remove' AS operation ,
  schema ,
  359 AS gumid ,
  id
FROM  
  td_criteo_result
WHERE
  proc_date = '${td.last_results.last_proc_date}' 
  AND segment_id = '${segment_id}'
