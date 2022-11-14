SELECT
  segment_name ,
  segment_tbl
FROM
  ${cdp[params].db}.${cdp[params].tbl}
GROUP BY
  1,2