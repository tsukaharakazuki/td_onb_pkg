SELECT
  ${media[params].key_id} 
  ${(Object.prototype.toString.call(media[params].add_columns) === '[object Array]')?','+media[params].add_columns.join():''}
  , time ,
  td_source ,
  td_medium ,
  td_campaign
FROM (
  SELECT
    * ,
    ROW_NUMBER() OVER (PARTITION BY ${media[params].key_id} ORDER BY time ASC) AS dum
  FROM
    l1_new_visitor_tmp
) t
WHERE
  dum = 1
