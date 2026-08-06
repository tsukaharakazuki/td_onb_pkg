-- ======================================================================
-- X (Twitter) Conversion API 送信用フォーマット
-- ======================================================================
-- Xにはコネクタが存在しないため、py_scripts/push_x.py がこのSQLの結果を
-- 直接取得し、X Ads API (POST /12/measurement/conversions/:pixel_id) へ送信する。
-- ======================================================================
SELECT
    event_id
    , event_time
    , em AS email
    , ph AS phone_number
    , client_ip_address AS ip_address
    , client_user_agent AS user_agent
    , CAST(value AS DOUBLE) AS value
FROM
    capi_send
WHERE
    em IS NOT NULL
    AND em \!= ''
