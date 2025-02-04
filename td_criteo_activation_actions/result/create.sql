SELECT
  userid ,
  name ,
  'add' AS operation ,
  schema ,
  359 AS gumid ,
  CAST(NULL AS varchar) AS id
FROM
  ${activation_actions_db}.${activation_actions_table}