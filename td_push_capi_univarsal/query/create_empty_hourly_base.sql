-- ======================================================================
-- 毎時送信無効時: 後続処理を安全にスキップする空ベース
-- ======================================================================
SELECT
    CAST(NULL AS VARCHAR) AS event_name
    , CAST(NULL AS BIGINT) AS event_time
    , CAST(NULL AS VARCHAR) AS event_id
    , CAST(NULL AS VARCHAR) AS em
    , CAST(NULL AS VARCHAR) AS ph
    , CAST(NULL AS VARCHAR) AS country
    , CAST(NULL AS BIGINT) AS value
    , CAST(NULL AS VARCHAR) AS currency
    , CAST(NULL AS VARCHAR) AS event_source_url
    , CAST(NULL AS VARCHAR) AS action_source
    , CAST(NULL AS VARCHAR) AS client_user_agent
    , CAST(NULL AS VARCHAR) AS client_ip_address
    , CAST(NULL AS VARCHAR) AS fbc
    , CAST(NULL AS VARCHAR) AS fbp
    , CAST(NULL AS VARCHAR) AS member_id
    , CAST(NULL AS VARCHAR) AS source_type
WHERE
    FALSE
