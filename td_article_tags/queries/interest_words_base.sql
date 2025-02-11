WITH t0 AS (
  SELECT
    user_id ,
    words ,
    SUM(weight) AS score
  FROM (
    SELECT
      a.user_id ,
      a.key ,
      a.pv ,
      b.words ,
      b.tfidf ,
      LOG10(a.pv * b.tfidf) AS weight
    FROM
      td_original_interest_words_access_log a
    INNER JOIN
      td_article_tags_tf_idf b
    ON
      a.key = b.key_id
  ) t
  GROUP BY
    1,2
)

-- DIGDAG_INSERT_LINE
SELECT
  * ,
  ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY score DESC) AS num
FROM
  t0