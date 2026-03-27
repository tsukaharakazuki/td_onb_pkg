-- ======================================================================
-- 共通: ブランド別送信済みチェック（テーブル存在確認込み）
-- ======================================================================
-- capi_push_log が存在しない場合は 0 を返す（初回実行）。
-- 存在する場合は、同一 event_id + brand_name の件数を返す。
-- already_sent > 0 → 送信済み（スキップ）
-- already_sent = 0 → 未送信（送信実行）
-- ======================================================================

SELECT
    COALESCE(
        (
            SELECT COUNT(*)
            FROM capi_push_log log
            INNER JOIN capi_send base
                ON CAST(log.event_id AS VARCHAR) = CAST(base.event_id AS VARCHAR)
            WHERE log.brand_name = '${b.brand_name}'
        )
        , 0
    ) AS already_sent
WHERE
    (
        SELECT COUNT(*)
        FROM information_schema.tables
        WHERE table_schema = '${common.database}'
            AND table_name = 'capi_push_log'
    ) > 0
UNION ALL
SELECT
    0 AS already_sent
WHERE
    (
        SELECT COUNT(*)
        FROM information_schema.tables
        WHERE table_schema = '${common.database}'
            AND table_name = 'capi_push_log'
    ) = 0
