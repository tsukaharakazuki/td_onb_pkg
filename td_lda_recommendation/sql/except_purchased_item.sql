WITH join_purchased_items AS (
  SELECT
    a.user_id ,
    a.recommend_item ,
    a.weight ,
    b.purchased_flag
  FROM
    td_lda_recommend_${set[params].name} a
  LEFT JOIN (
    SELECT
      USER_ID_COLUMN AS user_id ,
      PRODUCT_ID_COLUMN AS product_id ,
      '1' AS purchased_flag
    FROM
      POS_DATA_DB.POS_DATA_TBL
    GROUP BY
      1,2
  ) b
  ON
    a.user_id = CAST(b.user_id AS VARCHAR) 
    AND a.recommend_item = b.product_id
)

SELECT
  a.* ,
  ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY weight DESC) AS recommend_rank
FROM
  join_purchased_items
WHERE
  purchased_flag is NULL