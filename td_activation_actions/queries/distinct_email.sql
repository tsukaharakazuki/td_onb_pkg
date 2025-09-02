WITH t0 AS (
  SELECT 
    * ,
    ROW_NUMBER() OVER (PARTITION BY ${key_column} ORDER BY time) AS num
  FROM 
    ${activation_actions_db}.${activation_actions_table}
)

SELECT
  *
FROM
  t0
WHERE
  num = 1
