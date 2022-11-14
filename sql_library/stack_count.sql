WITH base AS (
  SELECT
    TD_TIME_FORMAT(time, 'yyyy-MM-dd', 'JST') AS purchase_day ,
    COUNT(*) AS cnt
  FROM
    TARGET_DATA_TABLE
  GROUP BY
    1
)

SELECT 
  purchase_day
  , cnt
  , SUM(cnt) OVER (ORDER BY purchase_day ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as stack
FROM (
  SELECT
    purchase_day
    , sum(cnt) as cnt
  FROM
    base
  group by
    1
)