SELECT
  user_id ,
  COLLECT_SET(words) AS original_interest_words
FROM 
  td_original_interest_words_base
WHERE
  num <= ${interest_words.num_om_words}
GROUP BY
  1
