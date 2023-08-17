WITH t0 AS (
  SELECT
    td_ms_id ,
    ${pred.colmuns} AS val ,
    CASE
      WHEN COUNT(*) = 1 THEN 'views_01'
      WHEN COUNT(*) BETWEEN 2 AND 5 THEN 'views_05'
      WHEN COUNT(*) BETWEEN 6 AND 15 THEN 'views_15'
      WHEN COUNT(*) BETWEEN 16 AND 30 THEN 'views_30'
      WHEN COUNT(*) BETWEEN 31 AND 50 THEN 'views_50'
      WHEN COUNT(*) >= 51 THEN 'views_51_over'
    END key 
  FROM
    ${media[params].output_db}.ms_behavior_${media[params].media_name}
  WHERE
    ${pred.colmuns} <> ''
    AND ${pred.colmuns} IS NOT NULL
  GROUP BY 
    1,2
)

, t1 AS (
  SELECT
    td_ms_id ,
    key ,
    ARRAY_AGG(val) AS vals
  FROM
    t0
  GROUP BY
    1,2
)


SELECT 
  td_ms_id,
  MAX(CASE WHEN key = 'views_01' THEN vals END) AS views_01_${pred.colmuns} ,
  MAX(CASE WHEN key = 'views_05' THEN vals END) AS views_05_${pred.colmuns} ,
  MAX(CASE WHEN key = 'views_15' THEN vals END) AS views_15_${pred.colmuns} ,
  MAX(CASE WHEN key = 'views_30' THEN vals END) AS views_30_${pred.colmuns} ,
  MAX(CASE WHEN key = 'views_50' THEN vals END) AS views_50_${pred.colmuns} ,
  MAX(CASE WHEN key = 'views_51_over' THEN vals END) AS views_51_over_${pred.colmuns}
FROM 
  t1
GROUP BY
  1
