WITH base AS (
  SELECT
    td_ms_id ,
    MAX_BY(user_id, if(user_id is null,null,time)) AS user_id ,
    SUM(td_progress) AS td_progress ,
    MAX_BY(td_recency,dum) AS td_recency ,
    SUM(td_frequency) AS td_frequency ,
    SUM(td_volume) AS td_volume ,
    MIN(time) AS time ,
    MIN(time) AS td_firsttime_web_unix ,
    1 AS dum
    ${(Object.prototype.toString.call(media[params].add_engagement_calc.sql) === '[object Array]')?','+media[params].add_engagement_calc.sql.join():''}
  FROM
    ms_attribute_engagement_score_${media[params].media_name}
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
