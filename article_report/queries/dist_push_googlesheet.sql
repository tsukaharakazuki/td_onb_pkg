SELECT 
  * ,
  '${tbl}' AS label 
FROM 
  ${tbl} 
WHERE 
  article_key = '${td.each.article_key}'