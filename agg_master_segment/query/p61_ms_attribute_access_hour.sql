WITH t0 AS (
  SELECT
    td_ms_id ,
    access_hour ,
    COUNT(*) AS cnt ,
    ROW_NUMBER() OVER (PARTITION BY td_ms_id ORDER BY COUNT(*) DESC) AS rnk
  FROM
    l1_audience_studio.ms_behavior_tsi
  WHERE
    TD_INTERVAL(time,'-90d','JST')
  GROUP BY
    td_ms_id ,
    access_hour 
)

SELECT
  td_ms_id ,
  MAX_BY(access_hour,cnt) AS td_top_hour ,
  '{"access_hour":{'||ARRAY_JOIN(ARRAY_AGG('"'||CAST(rnk AS VARCHAR)||'":"'||access_hour||'"'),',')||'}}' AS td_access_hour_json
FROM
  t0
GROUP BY
  1
