SELECT
  *
FROM
  ${db}.${tbl}
WHERE
  TD_INTERVAL(time, '-${span}d', 'JST')