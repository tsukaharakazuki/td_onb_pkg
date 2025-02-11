# Workflowについて
このWorkflowは、メディア・EC向けに、Webページコンテンツの全文の本文データを形態素解析にて単語抽出し、ユーザーのWeb閲覧データと組み合わせて、ユーザーごとに関心ワードを付与します。

# Hivemall
この処理内ではHivemallの`tokenize_ja`が利用されています。  
### 参考ドキュメント
https://qiita.com/myui/items/54f7fcce6bdeacd9674a