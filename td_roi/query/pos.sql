SELECT
  a.* ,
  b.*
FROM
  roi_behabior_online a
INNER JOIN (
  SELECT
    ${pos.time_col} AS time_purchace ,
    ${pos.user_id} AS user_id_purchace ,
    ${pos.amount_col} AS amount ,
    ROW_NUMBER() OVER () AS pos_num
    ${(Object.prototype.toString.call(pos.add_cols) === '[object Array]')?','+pos.add_cols.join():''}
  FROM
    ${pos.db}.${pos.tbl}
  WHERE
    TD_INTERVAL(${pos.time_col},'-1d','JST')
    ${(Object.prototype.toString.call(pos.where_condition) === '[object Array]')?'AND '+pos.where_condition.join(' AND '):''}
) b
ON
  a.user_id = b.user_id_purchace
  AND a.time BETWEEN TD_TIME_ADD(b.time_purchace, '-${roi_judge_date}d','JST') AND b.time_purchace