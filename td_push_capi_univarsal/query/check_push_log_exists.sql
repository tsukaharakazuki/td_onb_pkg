-- ======================================================================
-- 共通: capi_push_log テーブルの存在チェック
-- ======================================================================
SELECT
    COUNT(*) AS log_exists
FROM
    information_schema.tables
WHERE
    table_schema = '${common.database}'
    AND table_name = 'capi_push_log'
