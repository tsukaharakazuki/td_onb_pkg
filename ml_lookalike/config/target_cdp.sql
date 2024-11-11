SELECT
  segment_name ,
  REGEXP_REPLACE(
    LOWER(segment_tbl), '\s',''
  ) AS segment_tbl
FROM
  ${cdp[params].db}.${cdp[params].tbl}
WHERE
  TD_DATE_TRUNC('day',time,'JST') = TD_DATE_TRUNC('day',TD_SCHEDULED_TIME(),'JST')
GROUP BY
  1,2
