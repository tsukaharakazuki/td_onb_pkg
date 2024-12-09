WITH t0 AS (
  SELECT
    ${web[param].key_id} as key_id ,
    CASE
      WHEN REGEXP_REPLACE(REGEXP_REPLACE(TD_IP_TO_LEAST_SPECIFIC_SUBDIVISION_NAME(td_ip), '^Ō', 'O'), 'ō', 'o') = '${capital}' THEN 'capital'
      ELSE 'other'
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
      WHEN key = 'capital' THEN value
    END
  ) AS td_area_capital ,
  MAX(
    CASE
      WHEN key = 'other' THEN value
    END
  ) AS td_area_other
FROM
  t0
GROUP BY
  key_id