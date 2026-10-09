-- import: ${dp.name} / load_key: ${load_key}
SELECT
  src.*
  , '${load_key}' AS td_load_key
  , CAST(${time_expr} AS BIGINT) AS time
FROM (
${load_query}
) src
