WITH t0 AS (
  SELECT
    cdp_customer_id ,
    td_affinity_categorie
  FROM
    cdp_audience_${master_segment_id}.customers
  CROSS JOIN 
    UNNEST(td_affinity_categories) AS t(td_affinity_categorie)
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
)

SELECT
  td_affinity_categorie ,
  COUNT(*) AS population ,
  '${td.each.article_key}' AS article_key
FROM
  t0
GROUP BY
  1

