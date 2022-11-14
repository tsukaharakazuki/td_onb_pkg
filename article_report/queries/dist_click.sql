WITH t0 AS (
  SELECT
    COUNT(*) AS click_cnt ,
    '${td.each.value}' AS click_url ,
    '${td.each.article_key}' AS article_key
  FROM
    ${click_db}.${click_tbl}
  WHERE
    td_host = '${td.each.target_host}' AND
    regexp_like(td_path,'${td.each.article_id}') AND
    regexp_like(${click_col},'${td.each.value}') AND
    ${click_col} <> '' AND
    TD_TIME_RANGE(time,
      '${td.each.start_date}',
      '${td.each.end_date}',
      'JST'
    ) 
)

SELECT
  a.article_key ,
  a.click_url ,
  a.click_cnt ,
  CAST(a.click_cnt as double) / b.pv * 100 AS click_ctr
FROM
  t0 a
INNER JOIN (
  SELECT
    article_key ,
    pv
  FROM
    pvuu_total 
  WHERE
    article_key = '${td.each.article_key}'
    AND type = 'total'
) b
ON
  a.article_key = b.article_key