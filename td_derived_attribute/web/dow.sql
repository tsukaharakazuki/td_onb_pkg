WITH t0 AS (
  SELECT
    ${web[param].key_id} as key_id ,
    TD_TIME_FORMAT(time,'EEE','JST') AS key ,
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
      WHEN key = 'Sun' THEN value
    END
  ) AS td_pv_sun ,
  MAX(
    CASE
      WHEN key = 'Mon' THEN value
    END
  ) AS td_pv_mon ,
  MAX(
    CASE
      WHEN key = 'Tue' THEN value
    END
  ) AS td_pv_tue ,
  MAX(
    CASE
      WHEN key = 'Wed' THEN value
    END
  ) AS td_pv_wed ,
  MAX(
    CASE
      WHEN key = 'Thu' THEN value
    END
  ) AS td_pv_thu ,
  MAX(
    CASE
      WHEN key = 'Fri' THEN value
    END
  ) AS td_pv_fri ,
  MAX(
    CASE
      WHEN key = 'Sat' THEN value
    END
  ) AS td_pv_sat 
FROM
  t0
GROUP BY
  key_id