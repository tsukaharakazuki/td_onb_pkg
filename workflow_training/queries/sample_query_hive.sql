WITH t0 AS (
  SELECT
    time ,
    id_col 
  FROM
    hive_tbl
)

-- DIGDAG_INSERT_LINE
SELECT
  id_col ,
  MAX(time) AS time 
FROM
  t0
GROUP BY
  1
