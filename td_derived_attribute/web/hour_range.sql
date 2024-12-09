WITH t0 AS (
  SELECT
    ${web[param].key_id} as key_id ,
    CASE
      WHEN CAST(TD_TIME_FORMAT(time,'HH','JST') AS INT) BETWEEN ${midnight} THEN 'midnight'
      WHEN CAST(TD_TIME_FORMAT(time,'HH','JST') AS INT) BETWEEN ${morning} THEN 'morning'
      WHEN CAST(TD_TIME_FORMAT(time,'HH','JST') AS INT) BETWEEN ${noon} THEN 'noon'
      WHEN CAST(TD_TIME_FORMAT(time,'HH','JST') AS INT) BETWEEN ${afternoon} THEN 'afternoon'
      WHEN CAST(TD_TIME_FORMAT(time,'HH','JST') AS INT) BETWEEN ${night} THEN 'night'
    END key ,
    COUNT(*) AS value 
  FROM
    ${web[param].db}.${web[param].tbl}
  WHERE
    ${web[param].key_id} is not NULL
    AND TD_INTERVAL(time,'-${web[param].date_range}d','${time_zone}')
  GROUP BY
    1,2
)

-- DIGDAG_INSERT_LINE
SELECT
  key_id,
  MAX(
    CASE
      WHEN key = 'midnight' THEN value
    END
  ) AS td_hour_midnight ,
  MAX(
    CASE
      WHEN key = 'morning' THEN value
    END
  ) AS td_hour_morning ,
  MAX(
    CASE
      WHEN key = 'noon' THEN value
    END
  ) AS td_hour_noon ,
  MAX(
    CASE
      WHEN key = 'afternoon' THEN value
    END
  ) AS td_hour_afternoon ,
  MAX(
    CASE
      WHEN key = 'night' THEN value
    END
  ) AS td_hour_night
FROM
  t0
GROUP BY
  key_id