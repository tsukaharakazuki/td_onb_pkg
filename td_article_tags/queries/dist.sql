SELECT
  key_id ,
  COLLECT_SET(words) AS pickup_words
FROM 
  td_article_tags_tf_idf
WHERE
  num <= ${tokenize_ja.num_om_words}
GROUP BY
  1
