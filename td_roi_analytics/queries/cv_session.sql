SELECT
  ${target_session_id} AS cv_session_id
FROM
  ${weblog_db}.${weblog_tbl}
WHERE
  REGEXP_LIKE(
    ${td_url_col} ,
    '${conversion_urls.join("|")}'
  )
  ${span}
GROUP BY
  1