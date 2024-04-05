WITH base AS (
  SELECT
    td_ms_id ,
    MAX_BY(user_id_comp, if(user_id_comp is null,null,time)) AS user_id ,
    CAST((TD_DATE_TRUNC('day',unix_timestamp()) - TD_DATE_TRUNC('day',MIN(time))) / 86400 AS INT) AS td_progress ,
    CAST((TD_DATE_TRUNC('day',MAX(time)) - TD_DATE_TRUNC('day',unix_timestamp())) / 86400 AS INT) AS td_recency ,
    COUNT(DISTINCT TD_TIME_FORMAT(time,'yyyy-MM-dd','JST')) AS td_frequency ,
    COUNT(DISTINCT engagement_vols) AS td_volume ,
    MIN(time) AS time ,
    MIN(time) AS td_firsttime_unix ,
    1 AS dum
    ${(Object.prototype.toString.call(media[params].add_engagement_calc.sql) === '[object Array]')?','+media[params].add_engagement_calc.sql.join():''}
  FROM (
    SELECT
      * ,
      ROW_NUMBER() OVER (PARTITION BY td_ms_id ORDER BY time ASC) AS num
    FROM
      ${media[params].output_db}.ms_behavior_${media[params].media_name}
  ) t
  GROUP BY
    1
)
  
-- DIGDAG_INSERT_LINE
SELECT
  * ,
  td_recency * -1 AS td_recency_pn ,
  ntile(10) OVER (ORDER BY engagement_score ASC) AS decile
FROM (
  SELECT
    * ,
    log10(td_frequency * SQRT(td_volume)* (${td.last_results.progress} + td_recency + 1)) AS engagement_score
  FROM
    base
) t
