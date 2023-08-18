WITH t0 AS (
  SELECT
    td_ms_id ,
    media_name ,
    MAX(time) AS last_access_unix ,
    TD_TIME_FORMAT(MAX(time),'yyyy-MM-dd HH:mm:ss','JST') AS last_access
  FROM
    ${media[params].output_db}.ms_behavior_${media[params].media_name}
  GROUP BY
    1,2
)

SELECT
  * ,
  '最終アクセス | '||media_name||' '||last_access AS td_url ,
  last_access_unix AS time
FROM
  t0
