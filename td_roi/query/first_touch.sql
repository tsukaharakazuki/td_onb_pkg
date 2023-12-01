SELECT  
  time_purchace ,
  user_id ,
  amount 
  ${(Object.prototype.toString.call(pos.add_cols) === '[object Array]')?','+pos.add_cols.join():''}
  , td_source ,
  td_medium ,
  td_campaign ,
  td_smc ,
  time_inflow 
FROM (
  SELECT
    * ,
    ROW_NUMBER() OVER (PARTITION BY pos_num ORDER BY time_inflow ASC) AS dum
  FROM
    roi_behabior_purchace_yesterday
)
WHERE
  dum = 1 