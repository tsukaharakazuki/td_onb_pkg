WITH t0 AS (
  SELECT
    ${target.key} AS key_id ,
    CONCAT(${(Object.prototype.toString.call(target.texts) === '[object Array]')?target.texts.join(','):''}) AS text ,
    time
  FROM
    ${target.db}.${target.tbl}
  WHERE
    true
    ${(Object.prototype.toString.call(target.where_condition) === '[object Array]')?'AND '+target.where_condition.join(' AND '):''}
)

-- DIGDAG_INSERT_LINE
SELECT
  key_id ,
  MAX_BY(text, time) AS text
FROM
  t0
WHERE
  key_id is not NULL
GROUP BY
  1


