-- ======================================================================
-- Google Enhanced Conversions for Web 送信用フォーマット
-- ======================================================================
-- conversion_type: upload_enhanced_for_web
-- gclid不要。order_id + email/phone でユーザーマッチング。
-- ======================================================================
SELECT
    em AS email
    , ph AS phone_number
    , event_id AS order_id
    , '${b.google_conversion_action_id}' AS conversion_action_id
    , client_user_agent AS user_agent
FROM
    capi_send
WHERE
    em IS NOT NULL
    AND em \!= ''
