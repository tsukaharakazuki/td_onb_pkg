SELECT
  MAX(CASE WHEN cv_session_num = 1 THEN td_source END) OVER (PARTITION BY session_id) AS td_source_first ,
  MAX(CASE WHEN cv_session_num = 1 THEN td_medium END) OVER (PARTITION BY session_id) AS td_medium_first ,
  MAX(CASE WHEN cv_session_num = 1 THEN td_campaign END) OVER (PARTITION BY session_id) AS td_campaign_first ,
  LAG(td_source) OVER (PARTITION BY session_id ORDER BY cv_session_num ASC) AS td_source_recent ,
  LAG(td_medium) OVER (PARTITION BY session_id ORDER BY cv_session_num ASC) AS td_medium_recent ,
  LAG(td_campaign) OVER (PARTITION BY session_id ORDER BY cv_session_num ASC) AS td_campaign_recent ,
  *
FROM(
  SELECT
    * ,
    SPLIT(td_source_medium, '/')[1] AS td_source ,
    SPLIT(td_source_medium, '/')[2] AS td_medium ,
    ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY time ASC) AS cv_session_num
  FROM
    td_roi_prep_pv
)