WITH t0 AS (
  SELECT
    cdp_customer_id ,
    td_interest_word
  FROM
    cdp_audience_${master_segment_id}.customers 
  CROSS JOIN 
    UNNEST(td_interest_words) AS t(td_interest_word)
  WHERE
    ${key_id} IN (
      SELECT
        DISTINCT ${key_id}
      FROM
        ${log_db}.${log_tbl}
      WHERE
        td_host = '${td.each.target_host}' AND
        regexp_like(td_path,'${td.each.article_id}') AND
        TD_TIME_RANGE(time,
          '${td.each.start_date}',
          '${td.each.end_date}',
          'JST'
        ) 
    )
),

t1 AS (
  SELECT
    td_interest_word ,
    population ,
    RANK() OVER(ORDER BY population DESC) AS rnk 
  FROM (
    SELECT
      td_interest_word ,
      COUNT(*) AS population 
    FROM
      t0
    GROUP BY
      1
  )
)

SELECT
  td_interest_word ,
  population ,
  '${td.each.article_key}' AS article_key
FROM
  t1
WHERE
  rnk <= 200
