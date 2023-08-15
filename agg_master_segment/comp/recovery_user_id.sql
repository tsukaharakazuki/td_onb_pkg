SELECT
  td_ms_id ,
  'user_id' AS td_ms_id_type 
FROM (
  SELECT
    USER_ID_COL AS td_ms_id
  FROM
    USER_ID_DB.USER_ID_TBL
  GROUP BY
    1
  EXCEPT
  SELECT
    td_ms_id 
  FROM
    ms_behavior_${media[params].media_name}
)
