WITH t0 AS (
  SELECT
    ${set.id} as key_id ,
    SUM(
      IF(${set.true_key},1,0)
    ) AS target 
  FROM
    ${set.db}.${set.tbl}
  WHERE
    ${set.id} is not NULL
    ${(Object.prototype.toString.call(set.where_condition) === '[object Array]')?'AND '+set.where_condition.join(' AND '):''}
  GROUP BY
    1
)

-- DIGDAG_INSERT_LINE
SELECT
  key_id ,
  IF(target > 0,'true','false') AS td_tf_${set.output}
FROM
  t0