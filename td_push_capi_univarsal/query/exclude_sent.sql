-- ======================================================================
-- 共通: 送信済みデータ除外
-- ======================================================================
SELECT
    base.*
FROM
    capi_base base
LEFT JOIN (
    SELECT DISTINCT event_id
    FROM capi_push_log
) log
    ON CAST(base.event_id AS VARCHAR) = CAST(log.event_id AS VARCHAR)
WHERE
    log.event_id IS NULL
