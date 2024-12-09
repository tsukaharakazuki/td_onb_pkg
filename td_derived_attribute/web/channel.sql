WITH t0 AS (
  SELECT
    ${web[param].key_id} as key_id ,
    CASE
      WHEN td_source_medium RLIKE 'google|Google|GOOGLE' THEN 'google'
      WHEN td_source_medium RLIKE 'criteo|Criteo|CRITEO' THEN 'criteo'
      WHEN td_source_medium RLIKE 'yahoo|Yahoo|YAHOO' THEN 'yahoo'
      WHEN td_source_medium RLIKE 'line|Line|LINE' THEN 'line'
      WHEN td_source_medium RLIKE 'Facebook|facebook|(fb|Fb|FB)' THEN 'facebook'
      WHEN td_source_medium RLIKE 'Instagram|instagram|^(ig|Ig|IG)$' THEN 'instagram'
      WHEN td_source_medium RLIKE 'tiktok|Tiktok|TikTok|TIKTOK' THEN 'tiktok'
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
  MAX(CASE WHEN key = 'google' THEN value END) AS td_channel_google ,
  MAX(CASE WHEN key = 'criteo' THEN value END) AS td_channel_criteo ,
  MAX(CASE WHEN key = 'yahoo' THEN value END) AS td_channel_yahoo ,
  MAX(CASE WHEN key = 'line' THEN value END) AS td_channel_line ,
  MAX(CASE WHEN key = 'facebook' THEN value END) AS td_channel_facebook ,
  MAX(CASE WHEN key = 'instagram' THEN value END) AS td_channel_instagram ,
  MAX(CASE WHEN key = 'tiktok' THEN value END) AS td_channel_tiktok ,
  MAX(CASE WHEN key = 'other' THEN value END) AS td_channel_other 
FROM
  t0
WHERE
  key <> 'excluded'
GROUP BY
  key_id