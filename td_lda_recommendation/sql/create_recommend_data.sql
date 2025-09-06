WITH check_user_id AS (
  SELECT 
    CAST(${set[params].user_data.user_id} AS VARCHAR) AS user_id
  FROM 
    ${set[params].user_data.db}.${set[params].user_data.tbl}
  GROUP BY 
    1
)

, join_cluster AS (
  SELECT
    a.user_id ,
    b.cluster
  FROM
    check_user_id a
  LEFT JOIN 
    pred_${set[params].name} b
  ON
    a.user_id = CAST(b.uid AS VARCHAR)
)

SELECT
  a.* ,
  b.recommend_item ,
  b.weight ,
  b.weight_num
FROM
  join_cluster a 
LEFT JOIN (
  SELECT
    n_cluster ,
    word AS recommend_item ,
    weight ,
    ROW_NUMBER() OVER (PARTITION BY n_cluster ORDER BY weight DESC) AS weight_num
  FROM
    weights_${set[params].name}
  WHERE 
    NOT REGEXP_LIKE(a.word,'^TD_SUB_')
) b
ON
  a.cluster = b.n_cluster
WHERE
  b.weight_num <= ${item_num}
