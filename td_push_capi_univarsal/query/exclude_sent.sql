-- ======================================================================
-- 共通: 送信済みデータ除外
-- ======================================================================
-- capi_push_log テーブルのオーダーIDと突合し、未送信分のみ残す。
-- hourly / daily 両方のdigから共通で呼ばれる。
-- ======================================================================

SELECT
    base.*
FROM
    capi_base_${b.brand_name} base
LEFT JOIN
    capi_push_log log
    ON CAST(base.event_id AS VARCHAR) = CAST(log.event_id AS VARCHAR)
    AND log.brand_name = '${b.brand_name}'
WHERE
    log.event_id IS NULL
