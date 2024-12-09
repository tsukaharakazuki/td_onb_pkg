WITH t0 AS (
  SELECT
    ${web[param].key_id} as key_id ,
    CAST((TD_DATE_TRUNC('day',MAX(time)) - TD_DATE_TRUNC('day',unix_timestamp())) / 86400 AS INT) AS td_recency ,
    COUNT(DISTINCT TD_TIME_FORMAT(time,'yyyy-MM-dd','JST')) AS td_frequency ,
    COUNT(DISTINCT td_path) AS td_volume ,
    MIN(time) AS time 
  FROM
    ${web[param].db}.${web[param].tbl}
  WHERE
    ${web[param].key_id} is not NULL
    AND TD_INTERVAL(time,'-${web[param].date_range}d','${time_zone}')
  GROUP BY
    1
)

-- DIGDAG_INSERT_LINE
SELECT
  key_id ,
  td_recency ,
  td_frequency ,
  td_volume ,
  td_engagement_score ,
  ntile(10) OVER (ORDER BY engagement_score ASC) AS td_engagement_score_decile
FROM (
  SELECT
    * ,
    log10(td_frequency * SQRT(td_volume)* (${web[param].date_range} + td_recency + 1)) AS td_engagement_score
  FROM
    t0
) t
