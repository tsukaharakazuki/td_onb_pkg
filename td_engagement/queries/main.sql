SELECT
  * ,
  td_recency * -1 AS td_recency_pn ,
  ntile(10) OVER (ORDER BY engagement_score ASC) AS decile
FROM (
  SELECT
    * ,
    log10(td_frequency * SQRT(td_volume)* (${val.target_date} + td_recency + 2)) AS td_engagement_score
  FROM
    tmp_engagement_score_${val.label}
) t