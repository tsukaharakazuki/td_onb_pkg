SELECT
  * ,
  TD_SCHEDULED_TIME() AS insert_unix
FROM
  ${target_tbl}