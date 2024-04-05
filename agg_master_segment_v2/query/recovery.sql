SELECT
  td_ms_id ,
  'user_id' AS td_ms_id_type 
FROM (
  SELECT
    ${media[params].recovery.key} AS td_ms_id
  FROM
    ${media[params].recovery.db}.${media[params].recovery.tbl}
  GROUP BY
    1
  EXCEPT
  SELECT
    td_ms_id 
  FROM
    ms_behavior_${media[params].media_name}
)
