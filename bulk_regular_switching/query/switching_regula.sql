WITH t0 AS (
  SELECT
    ${(Object.prototype.toString.call(vals[params].fixed_cols) === '[object Array]')?vals[params].fixed_cols.join(','):''}
    ${(Object.prototype.toString.call(vals[params].processing) === '[object Array]')?','+vals[params].processing.join(','):''}
  FROM
    ${vals[params].db}.${vals[params].tbl}
  ${(Object.prototype.toString.call(vals[params].where_regular) === '[object Array]')?'WHERE '+vals[params].where_regular.join(' AND '):''}
  GROUP BY
    ${(Object.prototype.toString.call(vals[params].fixed_cols) === '[object Array]')?vals[params].fixed_cols.join(','):''}
)
-- DIGDAG_INSERT_LINE
SELECT
  * ,
  ${vals[params].td_url} AS td_url
FROM
  t0