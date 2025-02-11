SELECT
  key_id ,
  text ,
  words
FROM
  td_article_tags_base 
LATERAL VIEW EXPLODE (
  tokenize_ja(
    ${tokenize_ja.col_text}  --分解したいカラム
    , "normal"  -- normal/search/extended 
    , ${tokenize_ja.stopwords}  --const list<string> stopWords
    , ${tokenize_ja.stoptags}  --const list<string> stopTags
    --, NULL  --const array<string> userDict (or string userDictURL)
  )
) t AS words
