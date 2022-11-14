SELECT
  *
FROM
  sample_database.sample_table
WHERE
  TD_INTERVAL(time, '-1d', 'JST')