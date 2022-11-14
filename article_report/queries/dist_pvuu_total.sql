SELECT
  COUNT(*) AS pv ,
  COUNT(DISTINCT ${key_id}) AS uu ,
  'total' AS type ,
  '${td.each.article_key}' AS article_key
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

UNION ALL

SELECT
  COUNT(*) AS pv ,
  COUNT(DISTINCT ${key_id}) AS uu ,
  'smartphone' AS type ,
  '${td.each.article_key}' AS article_key
FROM
  ${log_db}.${log_tbl}
WHERE
  td_host = '${td.each.target_host}' AND
  regexp_like(td_path,'${td.each.article_id}') AND
  TD_TIME_RANGE(time,
    '${td.each.start_date}',
    '${td.each.end_date}',
    'JST'
  ) AND
  TD_PARSE_AGENT(td_user_agent) ['category'] = 'smartphone'

UNION ALL

SELECT
  COUNT(*) AS pv ,
  COUNT(DISTINCT ${key_id}) AS uu ,
  'pc' AS type ,
  '${td.each.article_key}' AS article_key
FROM
  ${log_db}.${log_tbl}
WHERE
  td_host = '${td.each.target_host}' AND
  regexp_like(td_path,'${td.each.article_id}') AND
  TD_TIME_RANGE(time,
    '${td.each.start_date}',
    '${td.each.end_date}',
    'JST'
  ) AND
  TD_PARSE_AGENT(td_user_agent) ['category'] = 'pc'