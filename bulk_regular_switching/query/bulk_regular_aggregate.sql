SELECT
  ${(Object.prototype.toString.call(vals[params].fixed_cols) === '[object Array]')?vals[params].fixed_cols.join(','):''}
  ${(Object.prototype.toString.call(vals[params].processing) === '[object Array]')?','+vals[params].processing.join(','):''}
  ,MAX_BY(td_url,time) AS td_url
FROM
  ${vals[params].output_db}.tmp_${vals[params].output_tbl}
GROUP BY
  ${(Object.prototype.toString.call(vals[params].fixed_cols) === '[object Array]')?vals[params].fixed_cols.join(','):''}