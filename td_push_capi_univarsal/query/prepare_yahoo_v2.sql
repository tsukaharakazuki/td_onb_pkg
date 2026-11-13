-- ======================================================================
-- Yahoo / LINE v2: 送信対象を確定（出力・送信ログで同じ行集合を使用）
-- ======================================================================
-- ly_su / ly_c / ly_r は「<timestamp>.<id>」形式のみ採用し、それ以外は空欄扱い。
-- 電話番号は数字と先頭の+以外を除去する（64桁のハッシュ値はそのまま）。
-- 不足・期限切れ・通貨不正の行は送らず、ログにも記録しない。
-- 残りの形式チェックはコネクタが行う。skip_invalid_records=falseを推奨。
WITH checked AS (
    SELECT
        *
        , CASE WHEN REGEXP_LIKE(ly_su, '^[0-9]+\.') THEN ly_su END AS ly_su_valid
        , CASE WHEN REGEXP_LIKE(ly_c, '^[0-9]+\.') THEN ly_c END AS ly_c_valid
        , CASE WHEN REGEXP_LIKE(ly_r, '^[0-9]+\.') THEN ly_r END AS ly_r_valid
        , CASE
            WHEN REGEXP_LIKE(ph, '^[0-9a-fA-F]{64}$') THEN ph
            ELSE REGEXP_REPLACE(ph, '[^0-9+]', '')
        END AS phone_valid
    FROM
        capi_send
)

SELECT
    *
FROM
    checked
WHERE
    NULLIF(TRIM(event_id), '') IS NOT NULL
    AND LENGTH(event_id) <= 64
    AND event_time > 0
    AND event_time BETWEEN CAST(TO_UNIXTIME(CURRENT_TIMESTAMP) AS BIGINT) - 90 * 86400
                       AND CAST(TO_UNIXTIME(CURRENT_TIMESTAMP) AS BIGINT)
    AND UPPER(currency) IN ('JPY', 'USD')
    AND (
        NULLIF(TRIM(CAST(em AS VARCHAR)), '') IS NOT NULL
        OR NULLIF(TRIM(phone_valid), '') IS NOT NULL
        OR ly_su_valid IS NOT NULL
        OR ly_c_valid IS NOT NULL
        OR ly_r_valid IS NOT NULL
        OR NULLIF(TRIM(ifa), '') IS NOT NULL
        -- line_uidはchannel_id設定時のみ識別子として扱う
        OR (NULLIF(TRIM(line_uid), '') IS NOT NULL AND '${b.channel_id}' != '')
    )
