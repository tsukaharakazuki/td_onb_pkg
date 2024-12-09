WITH t0 AS (
  SELECT
    ${web[param].key_id} as key_id ,
    CASE
      WHEN td_source_medium RLIKE 'app|App|APP' THEN 'app'
      WHEN td_source_medium RLIKE 'sosial|Sosial' THEN 'sosial'
      WHEN td_source_medium RLIKE 'cpc|ad|AD|Ad|display|product|p-max|PMAX|ppc|banner|gdn|paid' THEN 'ad'
      WHEN td_source_medium RLIKE 'organic' THEN 'organic'
      WHEN td_source_medium RLIKE 'mail|Mail|MAIL' THEN 'email'
      WHEN td_source_medium RLIKE 'karte|Karte|KARTE' THEN 'karte'
      WHEN td_source_medium = '(direct)/(none)' THEN 'excluded'
      ELSE 'other'
    END key ,
    COUNT(*) AS value 
  FROM
    ${web[param].db}.${web[param].tbl}
  WHERE
    ${web[param].key_id} is not NULL
    AND TD_INTERVAL(time,'-${web[param].date_range}d','${time_zone}')
    AND session_num = 1
  GROUP BY
    1,2
)

-- DIGDAG_INSERT_LINE
SELECT
  key_id,
  MAX(CASE WHEN key = 'app' THEN value END) AS td_ref_app ,
  MAX(CASE WHEN key = 'sosial' THEN value END) AS td_ref_sosial ,
  MAX(CASE WHEN key = 'ad' THEN value END) AS td_ref_ad ,
  MAX(CASE WHEN key = 'organic' THEN value END) AS td_ref_organic ,
  MAX(CASE WHEN key = 'email' THEN value END) AS td_ref_email ,
  MAX(CASE WHEN key = 'karte' THEN value END) AS td_ref_karte ,
  MAX(CASE WHEN key = 'other' THEN value END) AS td_ref_other 
FROM
  t0
WHERE
  key <> 'excluded'
GROUP BY
  key_id