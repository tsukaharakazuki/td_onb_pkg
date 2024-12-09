WITH t0 AS (
  SELECT
    ${web[param].key_id} as key_id ,
    IF(
      TD_TIME_FORMAT(time,'EEE','JST') RLIKE 'Sun|Sat','holiday','weekday'
    ) AS key ,
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
      WHEN key = 'holiday' THEN value
    END
  ) AS td_pv_holiday ,
  MAX(
    CASE
      WHEN key = 'weekday' THEN value
    END
  ) AS td_pv_weekday 
FROM
  t0
GROUP BY
  key_id