SELECT 
  table_schema AS database_name ,
  table_name ,
  column_name ,
  data_type ,
  ordinal_position 
FROM
  information_schema.columns
WHERE
  table_schema = '${target[param].db}'
  ${(Object.prototype.toString.call(target[param].tbl) === '[object Array]')?'AND regexp_like(table_name,\'^('+target[param].tbl.join('|')+')$\')':''}

