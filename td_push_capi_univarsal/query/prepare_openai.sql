-- ======================================================================
-- OpenAI Ads: 送信対象を確定（出力・送信ログで同じ行集合を使用）
-- ======================================================================
-- source_typeはTD内のhourly/daily区分。APIのaction_sourceとは別。
-- WebイベントはURL必須。日次も実際のイベント発生元に合わせて設定する。
SELECT
    *
FROM
    capi_send
WHERE
    NULLIF(TRIM(event_id), '') IS NOT NULL
    AND event_time BETWEEN CAST(TO_UNIXTIME(CURRENT_TIMESTAMP) AS BIGINT) - 7 * 86400
                       AND CAST(TO_UNIXTIME(CURRENT_TIMESTAMP) AS BIGINT) + 600
    AND value_decimal IS NOT NULL
    AND REGEXP_LIKE(UPPER(currency), '^[A-Z]{3}$')
    AND (
        CASE WHEN source_type = 'daily'
            THEN '${b.openai_daily_action_source}'
            ELSE '${b.openai_action_source}'
        END != 'web'
        OR REGEXP_LIKE(event_source_url, '^https?://[^/?#\s]+')
    )
