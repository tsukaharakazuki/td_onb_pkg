SELECT
  ${brand[params].user.user_id} AS uid ,
  CASE
    WHEN '${brand[params].user.email.hash}' <> 'na' THEN ${brand[params].user.email.hash}
    WHEN '${brand[params].user.email.row}' <> 'na' THEN LOWER(TO_HEX(SHA256(TO_UTF8(${brand[params].user.email.row}))))
    ELSE CAST(NULL AS VARCHAR)
  END email ,
  CASE
    WHEN '${brand[params].user.phone.hash_meta}' <> 'na' THEN ${brand[params].user.phone.hash_meta}
    WHEN '${brand[params].user.phone.row}' <> 'na' THEN LOWER(TO_HEX(SHA256(TO_UTF8('81'||SUBSTR(REPLACE(CAST(${brand[params].user.phone.row} AS VARCHAR),'-',''),2)))))
    ELSE CAST(NULL AS VARCHAR)
  END phone_meta ,
  CASE
    WHEN '${brand[params].user.phone.hash_e164}' <> 'na' THEN ${brand[params].user.phone.hash_e164}
    WHEN '${brand[params].user.phone.row}' <> 'na' THEN LOWER(TO_HEX(SHA256(TO_UTF8('+81'||SUBSTR(REPLACE(CAST(${brand[params].user.phone.row} AS VARCHAR),'-',''),2)))))
    ELSE CAST(NULL AS VARCHAR)
  END phone_e164 ,
  CASE
    WHEN '${brand[params].user.gender}' <> 'na' AND ${brand[params].user.gender} = '${brand[params].user.male}' THEN 'm'
    WHEN '${brand[params].user.gender}' <> 'na' AND ${brand[params].user.gender} = '${brand[params].user.female}' THEN 'f'
    ELSE CAST(NULL AS VARCHAR)
  END gender ,
  IF('${brand[params].user.birth_date}' <> 'na',${brand[params].user.birth_date},CAST(NULL AS VARCHAR)) AS birth_date ,
  IF('${brand[params].user.first_name}' <> 'na',${brand[params].user.first_name},CAST(NULL AS VARCHAR)) AS first_name ,
  IF('${brand[params].user.last_name}' <> 'na',${brand[params].user.last_name},CAST(NULL AS VARCHAR)) AS last_name ,
  IF('${brand[params].user.prefecture}' <> 'na',${brand[params].user.prefecture},CAST(NULL AS VARCHAR)) AS prefecture ,
  IF('${brand[params].user.city}' <> 'na',${brand[params].user.city},CAST(NULL AS VARCHAR)) AS city ,
  IF('${brand[params].user.zip_code}' <> 'na',${brand[params].user.zip_code},CAST(NULL AS VARCHAR)) AS zip_code ,
  IF('${brand[params].user.country}' <> 'na','${brand[params].user.country}',CAST(NULL AS VARCHAR)) AS country ,
  IF('${brand[params].user.currency}' <> 'na','${brand[params].user.currency}',CAST(NULL AS VARCHAR)) AS currency 
FROM (
  SELECT
    * ,
    NULL AS na
  FROM
    ${brand[params].user.db}.${brand[params].user.tbl}
)