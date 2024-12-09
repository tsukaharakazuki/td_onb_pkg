WITH t0 AS (
  SELECT
    ${web[param].key_id} as key_id ,
    CASE
      WHEN CAST(TD_TIME_FORMAT(time,'MM','JST') AS INT) BETWEEN ${ss} THEN 'ss'
      ELSE 'aw'
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
      WHEN key = 'ss' THEN value
    END
  ) AS td_pv_ss ,
  MAX(
    CASE
      WHEN key = 'aw' THEN value
    END
  ) AS td_pv_aw 
FROM
  t0
GROUP BY
  key_id