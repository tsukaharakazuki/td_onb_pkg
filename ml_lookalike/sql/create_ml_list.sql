WITH t0 AS (
  SELECT
    uid AS td_ms_id ,
    MAX_BY(pred,time) AS score 
  FROM
    ${td.each.db}.${td.each.tbl}
  GROUP BY
    1
)

SELECT
  * ,
  ntile(10) OVER (ORDER BY score DESC) AS decile ,
  '${td.each.segment_name}' AS segment_name
FROM
  t0
