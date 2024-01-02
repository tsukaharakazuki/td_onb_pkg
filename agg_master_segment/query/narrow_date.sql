SELECT
  *
FROM
  ${media[params].output_db}.${val.tbl}
WHERE
  ${time_filter}
