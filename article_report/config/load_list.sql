SELECT
  article_id ,
  REGEXP_REPLACE(
    article_id,
    '\.|\/|\@|\#|\$|\%|\^|\&|\*|\(|\)|\-|\+|\=|\[|\]|\{|\}|,|:|;',
  '_') AS tbl_name ,
  article_key ,
  target_host ,
  start_date ,
  end_date ,
  list_page_url ,
  list_name_jp ,
  list_page_title ,
  check_click ,
  click1 ,
  click2 ,
  click3 ,
  click4 ,
  click5 ,
  check_read ,
  ROW_NUMBER() OVER (PARTITION BY article_id) AS article_num 
FROM 
  list_article_report
