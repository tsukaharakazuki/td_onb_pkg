WITH t0 AS (
  SELECT
    article_id,
    article_key ,
    check_click ,
    target_host ,
    start_date ,
    end_date ,
    t.key,
    t.value
  FROM
    list_article_report
  CROSS JOIN UNNEST (
    array['click1', 'click2', 'click3', 'click4', 'click5'],
    array[click1, click2, click3, click4, click5]
  ) AS t (key, value)
)

SELECT
  article_id,
  article_key ,
  check_click ,
  target_host ,
  start_date ,
  end_date ,
  key,
  value
FROM
  t0
WHERE
  value <> 'hoge'
