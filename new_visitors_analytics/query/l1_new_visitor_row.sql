SELECT
  ${media[params].key_id} 
  ${(Object.prototype.toString.call(media[params].add_columns) === '[object Array]')?','+media[params].add_columns.join():''}
  , time ,
  td_source ,
  td_medium ,
  utm_campaign AS td_campaign
FROM (
  SELECT
    * ,
    ROW_NUMBER() OVER (PARTITION BY ${media[params].key_id} ORDER BY time ASC) AS dum
  FROM
    ${media[params].log_db}.${media[params].log_tbl}
  WHERE
    session_num = 1
    AND ${time_filter}
) t
WHERE
  dum = 1
