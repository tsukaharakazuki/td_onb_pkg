-- @TD enable_cartesian_product:true
WITH excluded_stopwords AS (
  SELECT
    t.key_id ,
    t.words
  FROM
    td_article_tags_tokenize_ja t
  WHERE
    t.words NOT rlike '^.$|(.)\1+${(Object.prototype.toString.call(stopwords) === '[object Array]')?'|'+stopwords.join('|'):''}'
),

tf AS (
  SELECT
    key_id,
    words,
    freq
  FROM (
    SELECT
      key_id,
      tf(words) AS word2freq
    FROM
      excluded_stopwords
    GROUP BY
      key_id
  ) t
  LATERAL VIEW explode(word2freq) t2 AS words, freq
),

df AS (
  SELECT
    words,
    count(distinct key_id) docs
  FROM
    excluded_stopwords
  GROUP BY
    words
)

-- DIGDAG_INSERT_LINE

SELECT
  * ,
  ROW_NUMBER() OVER (PARTITION BY key_id ORDER BY tfidf DESC) AS num
FROM (
  SELECT
    tf.key_id,
    tf.words,
    tfidf(tf.freq, df.docs, n_all.n) AS tfidf
  FROM
    tf
    INNER JOIN (
      -- get the number of article
      SELECT count(*) AS n FROM (SELECT distinct key_id FROM tf) t 
      ) n_all
    JOIN df 
    ON (tf.words = df.words)
) t1
