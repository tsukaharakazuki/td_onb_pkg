SELECT
  article_id ,
  article_key ,
  target_host ,
  REGEXP_REPLACE(start_date, '(?<=^.{10}).*','') AS start_date ,
  REGEXP_REPLACE(end_date, '(?<=^.{10}).*','') AS end_date ,
  list_page_url ,
  list_name_jp ,
  list_page_title ,
  check_click ,
  click1 ,
  click2 ,
  click3 ,
  click4 ,
  click5 ,
  check_read   
FROM 
  install_list_article_report