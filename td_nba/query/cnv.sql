WITH extraction_session AS (
  SELECT
    session_id
  FROM
    ${list[param].target_db}.${list[param].target_tbl}
  WHERE
    TD_INTERVAL(time,'-${narrow_date}d','JST')
    AND media_name = '${list[param].target_brand}'
    ${(Object.prototype.toString.call(list[param].where_condition) === '[object Array]')?'AND '+list[param].where_condition.join(' AND '):''}
  GROUP BY
    1
)

SELECT
  * ,
  ROW_NUMBER() OVER (ORDER BY cnt DESC) AS cv_rank
FROM (
  SELECT
    td_source ,
    td_medium ,
    td_source||'/'||td_medium AS td_source_medium ,
    --utm_campaign ,
    --td_source||'/'||td_medium||'/'||utm_campaign AS td_smc ,
    COUNT(*) AS cnt
  FROM
    ${list[param].target_db}.${list[param].target_tbl} a
  INNER JOIN 
    extraction_session b
  ON
    a.session_id = b.session_id
  WHERE
    TD_INTERVAL(time,'-${narrow_date}d','JST')
    AND session_num = 1
  GROUP BY
    1,2,3 
)
WHERE
    NOT REGEXP_LIKE(td_source_medium,'^(${(Object.prototype.toString.call(exclusion_source_medium) === '[object Array]')?exclusion_source_medium.join('|'):''})$')