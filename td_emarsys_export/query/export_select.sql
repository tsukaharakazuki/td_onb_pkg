-- 送信データ抽出（汎用）
-- SFTP / WebDAV の両方から呼ばれる。中身は config/{sftp,webdav}.yml の targets で切り替える
SELECT
    ${targets[target].columns}
FROM
    ${targets[target].source_db}.${targets[target].source_table}
WHERE
    ${targets[target].where}
