SELECT
  '- '||column_name
FROM
  information_schema.columns
WHERE
  table_schema = 'DATABASE_NAME'
  AND table_name = 'TABLE_NAME'
  AND NOT REGEXP_LIKE(
    column_name ,
    '^(td_platform|td_title|td_browser|td_color|td_description|td_path|td_global_id|td_user_agent|td_ip|td_version|td_client_id|td_os_version|td_browser_version|td_viewport|td_charset|td_os|td_referrer|td_screen|td_host|td_url|td_language|td_ssc_id|time)$'
  )
ORDER BY
  1
