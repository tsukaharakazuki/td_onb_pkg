SELECT
  *
FROM
  ${media[params].output_db}.${val.tbl}
WHERE
  TD_INTERVAL(time,'-1d','JST')
