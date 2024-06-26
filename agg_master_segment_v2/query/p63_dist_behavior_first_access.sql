SELECT
  time ,
  td_ms_id ,
  media_name ,
  td_source ,
  td_medium ,
  td_campaign ,
  time AS first_access_unix ,
  TD_TIME_FORMAT(time,'yyyy-MM-dd HH:mm:ss','JST') AS first_access ,
  CONCAT('初回アクセス | ',media_name,' ',TD_TIME_FORMAT(time,'yyyy-MM-dd HH:mm:ss','JST')) AS td_url 
FROM (
  SELECT
    * ,
    ROW_NUMBER() OVER (PARTITION BY td_ms_id,media_name ORDER BY time ASC) AS num
  FROM
    ${media[params].output_db}.tmp_ms_behavior_first_access_${media[params].media_name}
) t
WHERE
  num = 1
