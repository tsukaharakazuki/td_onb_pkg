SELECT
  ${interest_words.user_id} AS user_id ,
  ${interest_words.key} AS key ,
  COUNT(*) AS pv
FROM
  ${interest_words.db}.${interest_words.tbl}
WHERE
  TD_INTERVAL(time,'-${interest_words.span}d','JST')
  AND ${interest_words.key} is not NULL
GROUP BY
  1,2