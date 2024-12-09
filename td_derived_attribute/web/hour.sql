WITH t0 AS (
  SELECT
    ${web[param].key_id} as key_id ,
    CAST(TD_TIME_FORMAT(time,'HH','JST') AS INT) AS key ,
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
      WHEN key = 0 THEN value
    END
  ) AS td_hour_0,
  MAX(
    CASE
      WHEN key = 1 THEN value
    END
  ) AS td_hour_1,
  MAX(
    CASE
      WHEN key = 2 THEN value
    END
  ) AS td_hour_2,
  MAX(
    CASE
      WHEN key = 3 THEN value
    END
  ) AS td_hour_3,
  MAX(
    CASE
      WHEN key = 4 THEN value
    END
  ) AS td_hour_4,
  MAX(
    CASE
      WHEN key = 5 THEN value
    END
  ) AS td_hour_5,
  MAX(
    CASE
      WHEN key = 6 THEN value
    END
  ) AS td_hour_6,
  MAX(
    CASE
      WHEN key = 7 THEN value
    END
  ) AS td_hour_7,
  MAX(
    CASE
      WHEN key = 8 THEN value
    END
  ) AS td_hour_8,
  MAX(
    CASE
      WHEN key = 9 THEN value
    END
  ) AS td_hour_9,
  MAX(
    CASE
      WHEN key = 10 THEN value
    END
  ) AS td_hour_10,
  MAX(
    CASE
      WHEN key = 11 THEN value
    END
  ) AS td_hour_11,
  MAX(
    CASE
      WHEN key = 12 THEN value
    END
  ) AS td_hour_12,
  MAX(
    CASE
      WHEN key = 13 THEN value
    END
  ) AS td_hour_13,
  MAX(
    CASE
      WHEN key = 14 THEN value
    END
  ) AS td_hour_14,
  MAX(
    CASE
      WHEN key = 15 THEN value
    END
  ) AS td_hour_15,
  MAX(
    CASE
      WHEN key = 16 THEN value
    END
  ) AS td_hour_16,
  MAX(
    CASE
      WHEN key = 17 THEN value
    END
  ) AS td_hour_17,
  MAX(
    CASE
      WHEN key = 18 THEN value
    END
  ) AS td_hour_18,
  MAX(
    CASE
      WHEN key = 19 THEN value
    END
  ) AS td_hour_19,
  MAX(
    CASE
      WHEN key = 20 THEN value
    END
  ) AS td_hour_20,
  MAX(
    CASE
      WHEN key = 21 THEN value
    END
  ) AS td_hour_21,
  MAX(
    CASE
      WHEN key = 22 THEN value
    END
  ) AS td_hour_22,
  MAX(
    CASE
      WHEN key = 23 THEN value
    END
  ) AS td_hour_23
FROM
  t0
GROUP BY
  key_id