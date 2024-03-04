WITH base AS (
  SELECT
    td_ms_id ,
    MIN_BY(td_source_first,dum) AS td_source_first ,
    MIN_BY(td_medium_first,dum) AS td_medium_first ,
    MIN_BY(td_campaign_first,dum) AS td_campaign_first ,
    MAX_BY(user_id, if(user_id is null,null,time)) AS user_id ,
    SUM(td_progress_web) AS td_progress_web ,
    MAX_BY(td_recency_web,dum) AS td_recency_web ,
    SUM(td_frequency_web) AS td_frequency_web ,
    SUM(td_volume_web) AS td_volume_web ,
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
  td_recency_web * -1 AS td_recency_web_pn ,
  ntile(10) OVER (ORDER BY engagement_score ASC) AS decile
FROM (
  SELECT
    * ,
    log10(td_frequency_web * SQRT(td_volume_web)* (${td.last_results.progress} + td_recency_web + 1)) AS engagement_score
  FROM
    base
) t
