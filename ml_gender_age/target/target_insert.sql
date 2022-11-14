SELECT
  ${target[params].key} AS uid ,
  MAX_BY(${target[params].age},${target[params].sort}) AS age ,
  CASE
    WHEN MAX_BY(${target[params].gender},${target[params].sort}) =  ${target[params].male} THEN 'M'
    WHEN MAX_BY(${target[params].gender},${target[params].sort}) =  ${target[params].female} THEN 'F'
    ELSE NULL
  END gender
FROM
  ${target[params].db}.${target[params].tbl}
WHERE
  ${target[params].key} is not NULL
  AND ${target[params].gender} is not NULL
  AND ${target[params].age} BETWEEN 6 AND 100
GROUP BY 
  1