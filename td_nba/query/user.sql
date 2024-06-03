  SELECT
    * ,
    ROW_NUMBER() OVER (PARTITION BY td_ms_id ORDER BY inflow DESC) AS inflow_rank
  FROM
    ${inflow.db}.${inflow.tbl} 
  WHERE
    NOT REGEXP_LIKE(inflow_source_medium,'^(${(Object.prototype.toString.call(exclusion_source_medium) === '[object Array]')?exclusion_source_medium.join('|'):''})$')