WITH target_session AS (
  SELECT
    ${td_session_id} 
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
  GROUP BY
    1
)

, t0 AS (
  SELECT
    TD_TIME_FORMAT(time, 'yyyy-MM-dd', 'JST') AS date ,
    SPLIT(source_medium, '/')[1] AS td_source ,
    SPLIT(source_medium, '/')[2] AS td_medium ,
    COUNT(*) AS pv ,
    COUNT(DISTINCT ${key_id}) AS uu 
  FROM (
    SELECT
      time ,
      ${key_id} ,
      ${td_session_num} ,
      CASE
        WHEN td_ref_host = '' OR td_ref_host = td_host OR td_ref_host is NULL
          THEN '(direct)/(none)'
        WHEN REGEXP_LIKE(td_ref_host, '(mail)\.(google|yahoo|nifty|excite|ocn|odn|jimdo)\.')
          THEN CONCAT(REGEXP_EXTRACT(td_ref_host, '(mail)\.(google|yahoo|nifty|excite|ocn|odn|jimdo)\.', 2), '/mail')
        WHEN REGEXP_LIKE(td_ref_host, '^outlook.live.com$')
          THEN 'outlook/mail'
        WHEN REGEXP_LIKE(td_ref_host, '\.*(facebook|instagram|line|ameblo)\.')
          THEN CONCAT(REGEXP_EXTRACT(td_ref_host, '\.*(facebook|instagram|line|ameblo)\.', 1), '/social')
        WHEN REGEXP_LIKE(td_ref_host, '^t.co$')
          THEN 'twitter/social'
        WHEN REGEXP_LIKE(td_ref_host, '\.(criteo|outbrain)\.')
          THEN CONCAT(REGEXP_EXTRACT(td_ref_host, '\.(criteo|outbrain)\.', 1), '/display')
        WHEN REGEXP_LIKE(td_ref_host, '(search)*\.*(google|yahoo|biglobe|nifty|goo|so-net|livedoor|rakuten|auone|docomo|naver|hao123|myway|dolphin-browser|fenrir|norton|uqmobile|net-lavi|newsplus|jword|ask|myjcom|1and1|excite|mysearch|kensakuplus)\.')
          THEN CONCAT(REGEXP_EXTRACT(td_ref_host, '(search)*\.*(google|yahoo|biglobe|nifty|goo|so-net|livedoor|rakuten|auone|docomo|naver|hao123|myway|dolphin-browser|fenrir|norton|uqmobile|net-lavi|newsplus|jword|ask|myjcom|1and1|excite|mysearch|kensakuplus)\.', 2), '/organic')
        WHEN td_ref_host = 'kids.yahoo.co.jp' AND SPLIT_PART(URL_EXTRACT_PATH(td_referrer), '/', 2) = 'search' THEN 'yahoo/organic'
        ELSE CONCAT(td_ref_host, '/referral')
      END source_medium 
    FROM
      ${log_db}.${log_tbl} a
    INNER JOIN
      target_session b
    ON
      a.${td_session_id} = b.${td_session_id}
    WHERE
      TD_TIME_RANGE(time,
        '${td.each.start_date}',
        '${td.each.end_date}',
        'JST'
      ) 
  )
  WHERE
    ${td_session_num} = 1
  GROUP BY 
    1,2,3
)

, target_ref AS (
  SELECT
    td_source 
  FROM(
    SELECT
      td_source ,
      pv ,
      RANK() OVER(ORDER BY pv DESC) AS rnk 
    FROM(
      SELECT
        td_source ,
        SUM(pv) AS pv
      FROM
        t0
      GROUP BY
        1
    )
  )
  WHERE
    rnk <= 10
)


SELECT
  a.date ,
  a.td_source ,
  a.td_medium ,
  a.pv ,
  a.uu ,
  '${td.each.article_key}' AS article_key
FROM 
  t0 a
INNER JOIN
  target_ref b
ON
  a.td_source = b.td_source
