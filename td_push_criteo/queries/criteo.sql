SELECT
  userid ,
  name ,
  operation ,
  schema ,
  359 AS gumid ,
  IF(id = 'NULL',NULL,id) AS id
FROM  
  td_criteo.${segnment_target_tbl}
WHERE
  TD_INTERVAL(time,'1d','JST')
  AND userid is not NULL
  AND name = '${td.each.name}'
