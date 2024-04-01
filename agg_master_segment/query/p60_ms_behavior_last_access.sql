SELECT
  td_ms_id ,
  media_name ,
  MAX(time) AS time ,
  MAX(time) AS last_access_unix ,
  TD_TIME_FORMAT(MAX(time),'yyyy-MM-dd HH:mm:ss','JST') AS last_access ,
  CONCAT('最終アクセス | ',media_name,' ',TD_TIME_FORMAT(MAX(time),'yyyy-MM-dd HH:mm:ss','JST')) AS td_url 
FROM
  ${media[params].output_db}.ms_behavior_${media[params].media_name}
WHERE
  ${time_filter}
GROUP BY
  1,2
