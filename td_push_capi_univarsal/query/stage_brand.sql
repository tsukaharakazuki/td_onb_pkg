-- ======================================================================
-- 共通: ブランド・媒体ごとの未送信行を抽出（送信対象の絞り込みはここでは行わない）
-- ======================================================================
-- 送信済みは capi_push_log の brand_name + platform + event_id で判定する。
-- platform が空の旧ログ行は brand_name だけで一致させ、移行後に再送しないようにする。
-- 媒体ごとの適格条件（メアドの有無など）は各 push / prepare SQL で行い、
-- 送信ログはその適格条件を通過した行だけを記録する。
-- ======================================================================
SELECT
    base.*
FROM
    capi_base base
LEFT JOIN (
    SELECT DISTINCT event_id
    FROM capi_push_log
    WHERE brand_name = '${b.brand_name}'
        AND COALESCE(platform, '${b.platform}') = '${b.platform}'
) log
    ON CAST(base.event_id AS VARCHAR) = CAST(log.event_id AS VARCHAR)
WHERE
    log.event_id IS NULL
