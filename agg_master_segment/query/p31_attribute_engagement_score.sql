WITH tmp AS (
  SELECT  
    td_ms_id ,
    td_source_first ,
    td_medium_first ,
    td_campaign_first ,
    user_id ,
    td_progress_web ,
    td_recency_web ,
    td_frequency_web ,
    td_volume_web ,
    time ,
    1 AS dum
    ${(Object.prototype.toString.call(media[params].add_engagement_calc.sql) === '[object Array]')?','+media[params].add_engagement_calc.sql.join():''}
  FROM
    ms_attribute_engagement_score_${media[params].media_name}

  UNION ALL
  
  SELECT
    td_ms_id ,
    MIN_BY(ms_utm_source,num) AS td_source_first ,
    MIN_BY(ms_utm_medium,num) AS td_medium_first ,
    MIN_BY(ms_utm_campaign,num) AS td_campaign_first ,
    MAX_BY(user_id_comp, if(user_id_comp is null,null,time)) AS user_id ,
    CAST((TD_DATE_TRUNC('day',unix_timestamp()) - TD_DATE_TRUNC('day',MIN(time))) / 86400 AS INT) AS td_progress_web ,
    CAST((TD_DATE_TRUNC('day',MAX(time)) - TD_DATE_TRUNC('day',unix_timestamp())) / 86400 AS INT) AS td_recency_web ,
    COUNT(DISTINCT TD_TIME_FORMAT(time,'yyyy-MM-dd','JST')) AS td_frequency_web ,
    COUNT(DISTINCT engagement_vols) AS td_volume_web ,
    MIN(time) AS time ,
    2 AS dum
    ${(Object.prototype.toString.call(media[params].add_engagement_calc.sql) === '[object Array]')?','+media[params].add_engagement_calc.sql.join():''}
  FROM (
    SELECT
      * ,
      ROW_NUMBER() OVER (PARTITION BY td_ms_id ORDER BY time ASC) AS num
    FROM
      ${media[params].output_db}.ms_behavior_${media[params].media_name}
    WHERE
      TD_INTERVAL(time,'-1d','JST')
  ) t
  GROUP BY
    1
)

, base AS (
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
    MIN(time) AS time 
    ${(Object.prototype.toString.call(media[params].add_engagement_calc.sql) === '[object Array]')?','+media[params].add_engagement_calc.sql.join():''}
  FROM
    tmp
  GROUP BY
    1
)

-- DIGDAG_INSERT_LINE
SELECT
  * ,
  td_recency_web * -1 AS td_recency_web_pn ,
  ntile(10) OVER (ORDER BY engagement_score DESC) AS decile
FROM (
  SELECT
    * ,
    log10(td_frequency_web * SQRT(td_volume_web)* (${td.last_results.progress} + td_recency_web + 1)) AS engagement_score
  FROM
    base
) t
