SELECT
  key ,
  val
FROM
  db.tbl
CROSS JOIN 
  UNNEST(array_col) AS t(val)