SELECT
  TD_TIME_FORMAT(time, 'yyyy-MM-dd', 'JST') AS date ,
  COUNT(*) AS pv ,
  COUNT(DISTINCT id_col) AS uu
FROM
  for_each_table
WHERE
  TD_TIME_RANGE(
    time ,
    '${val.start}' ,
    '${val.end}' ,
    'JST'
  )