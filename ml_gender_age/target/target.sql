WITH t0 AS (
  SELECT
    uid ,
    gender ,
    floor(cast(age as integer) / ${age_range}) * ${age_range} AS age${age_range} ,
    CASE
      when cast(age as integer) < 20 then 'C'
      when gender = 'M' and cast(age as integer) between 20 and 34 then 'M1'
      when gender = 'M' and cast(age as integer) between 35 and 49 then 'M2'
      when gender = 'M' and cast(age as integer) between 50 and 64 then 'M3'
      when gender = 'M' and cast(age as integer) >= 65 then 'M4'
      when gender = 'F' and cast(age as integer) between 20 and 34 then 'F1'
      when gender = 'F' and cast(age as integer) between 35 and 49 then 'F2'
      when gender = 'F' and cast(age as integer) between 50 and 64 then 'F3'
      when gender = 'F' and cast(age as integer) >= 65 then 'F4'
    END as target${age_range} ,
    gender || cast(floor(cast(age as integer) / ${age_range}) * ${age_range} as varchar) AS target
  FROM
    base_target
  WHERE
    age is not NULL
    AND gender is not NULL
)

SELECT
  a.cookie AS uid ,
  b.gender ,
  b.age${age_range} ,
  b.target${age_range} ,
  b.target
FROM
  map_uid_cookie a
INNER JOIN (
  SELECT
    uid ,
    MAX(gender) AS gender ,
    MAX(age${age_range}) AS age${age_range} ,
    MAX(target${age_range}) AS target${age_range} ,
    MAX(target) AS target
  FROM
    t0
  GROUP BY
    1
) b
ON
  a.uid = b.uid