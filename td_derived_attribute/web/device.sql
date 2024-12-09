WITH t0 AS (
  SELECT
    ${web[param].key_id} as key_id ,
    TD_PARSE_AGENT(td_user_agent)['vendor'] AS key ,
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
      WHEN key = 'smartphone' THEN value
    END
  ) AS td_device_sp ,
  MAX(
    CASE
      WHEN key = 'pc' THEN value
    END
  ) AS td_device_pc 
FROM
  t0
GROUP BY
  key_id