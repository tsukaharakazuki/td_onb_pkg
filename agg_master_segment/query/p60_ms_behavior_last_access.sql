WITH t0 AS (
  SELECT
    td_ms_id ,
    media_name ,
    last_access_unix
  FROM
    ${media[params].output_db}.tmp_ms_behavior_last_access_${media[params].media_name}

  UNION ALL

  SELECT
    td_ms_id ,
    media_name ,
    MAX(time) AS last_access_unix 
  FROM
    ${media[params].output_db}.ms_behavior_${media[params].media_name}
  WHERE
    TD_INTERVAL(time,'-1d','JST')
  GROUP BY
    1,2
)

, t1 AS (
  SELECT
    td_ms_id ,
    media_name ,
    MAX(last_access_unix) AS last_access_unix ,
    TD_TIME_FORMAT(MAX(last_access_unix),'yyyy-MM-dd HH:mm:ss','JST') AS last_access
  FROM
    t0
  GROUP BY
    1,2
)

SELECT
  * ,
  '最終アクセス | '||media_name||' '||last_access AS td_url
FROM
  t1
