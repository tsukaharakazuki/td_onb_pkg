WITH t0 AS (
  SELECT
    ${web[param].key_id} as key_id ,
    CASE
      WHEN CAST(TD_TIME_FORMAT(time,'MM','JST') AS INT) BETWEEN ${spring} THEN 'spring'
      WHEN CAST(TD_TIME_FORMAT(time,'MM','JST') AS INT) BETWEEN ${summer} THEN 'summer'
      WHEN CAST(TD_TIME_FORMAT(time,'MM','JST') AS INT) BETWEEN ${autumn} THEN 'autumn'
      ELSE 'winter'
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
      WHEN key = 'spring' THEN value
    END
  ) AS td_pv_spring ,
  MAX(
    CASE
      WHEN key = 'summer' THEN value
    END
  ) AS td_pv_summer ,
  MAX(
    CASE
      WHEN key = 'autumn' THEN value
    END
  ) AS td_pv_autumn ,
  MAX(
    CASE
      WHEN key = 'winter' THEN value
    END
  ) AS td_pv_winter 
FROM
  t0
GROUP BY
  key_id