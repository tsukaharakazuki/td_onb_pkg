WITH t0 AS (
  SELECT
    td_source_first ,
    td_medium_first ,
    td_campaign_first ,
    td_source_recent ,
    td_medium_recent ,
    td_campaign_recent ,
    user_id ,
    'e'||td_order_id AS td_order_id ,
    time
  FROM
    td_roi_dist_order_pv
  WHERE
    td_order_id is not NULL
)

SELECT
  a.* ,
  b.${amount_col} AS total_amount
FROM
  t0 a
LEFT JOIN
  ${pos_db}.${pos_tbl} b
ON
  a.td_order_id = b.${pos_order_id}