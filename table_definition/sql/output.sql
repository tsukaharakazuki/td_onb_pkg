WITH tmp AS (
  SELECT
    a.database_name ,
    a.table_name ,
    a.ordinal_position ,
    a.column_name ,
    a.data_type ,
    a.sample ,
    b.col_info
  FROM
    td_table_definition a
  LEFT JOIN (
    SELECT 
      * 
    FROM (
      VALUES 
        ('time', 'UNIXタイム') , 
        ('td_url', 'URL') , 
        ('td_charset', '文字コード') ,
        ('td_description', 'ディスクリプション') ,
        ('td_browser_version', 'ブラウザバージョン') ,
        ('td_os', 'OS') ,
        ('td_ip', 'IPアドレス') ,
        ('td_browser', 'ブラウザ情報') ,
        ('td_referrer', 'リファラURL') ,
        ('td_version', 'td_js_sdkバージョン') ,
        ('td_title', 'サイトタイトル') ,
        ('td_language', 'PC言語設定') ,
        ('td_color', 'モニター色彩情報') ,
        ('td_os_version', 'OSバージョン') ,
        ('td_user_agent', 'ユーザーエージェント') ,
        ('td_platform', 'プラットフォーム') ,
        ('td_host', 'URLホスト') ,
        ('td_path', 'URLパス') ,
        ('td_screen', 'スクリーンサイズ') ,
        ('td_client_id', '1st Party cookie(Docment Cookie)') ,
        ('td_global_id', '3rd Party cookie(Docment Cookie)') ,
        ('td_ssc_id', '1st Party cookie(Server Side Cookie)') ,
        ('media_name', 'サイトソース名') ,
        ('td_data_type', 'pageview/click ログタイプ') ,
        ('access_date_time', 'アクセス日時 yyyy-MM-dd HH:mm:ss') ,
        ('access_date', 'アクセス日 yyyy-MM-dd') ,
        ('access_hour', 'アクセス時 HH') ,
        ('week', '週番号') ,
        ('dow', '曜日') ,
        ('ampm', '午前午後') ,
        ('session_start_time', 'セッション開始UNIXTIME') ,
        ('session_end_time', 'セッション終了UNIXTIME') ,
        ('session_id', 'セッションID') ,
        ('session_num', 'セッション番号') ,
        ('browsing_sec', '滞在時間（秒）') ,
        ('td_cookie', '正規化したCookie（td_ssc_id/td_client_id/td_global_id）') ,
        ('td_cookie_type', '正規化したCookieタイプ（td_ssc_id/td_client_id/td_global_id）') ,
        ('user_id', 'ユーザーID') ,
        ('user_id_comp', 'セッション途中でログインした場合の補完') ,
        ('utm_campaign', 'UTMキャンペーン') ,
        ('utm_medium', 'UTMメディア') ,
        ('utm_source', 'UTMソース') ,
        ('utm_term', 'UTMターム') ,
        ('td_source_medium', 'ソース/メディア') ,
        ('td_source', 'UTMがある場合UTMを採用し、無い場合はリファラ') ,
        ('td_medium', 'UTMがある場合UTMを採用し、無い場合はリファラ') ,
        ('td_ref_host', 'リファラアドレスのホスト') ,
        ('article_key', 'td_host/td_pathを結合') ,
        ('ua_os', 'ユーザーエージェントから取得したOS') ,
        ('ua_vendor', 'ユーザーエージェントから取得したベンダー') ,
        ('ua_os_version', 'ユーザーエージェントから取得したOSバージョン') ,
        ('ua_browser', 'ユーザーエージェントから取得したブラウザ名') ,
        ('ua_category', 'ユーザーエージェントから取得したPC/スマホ') ,
        ('ip_country', 'IPアドレスから取得した国名') ,
        ('ip_prefectures', 'IPアドレスから取得した都道府県名') ,
        ('ip_city', 'IPアドレスから取得した都市名 - 利用非推奨') ,
        ('td_proc_date', 'アグリゲート処理実行日') ,
        ('td_viewport', 'ビューポイントサイズ') 
        --追加がある場合以下に記入
        --入力例：, ('カラム名', '説明') 
        --, ('', '', '') 
    ) as cols(col_name, col_info);
  ) b
  ON
    a.column_name = b.col_name
  WHERE
    a.database_name = '${td.each.database_name}'
    AND a.table_name = '${td.each.table_name}'
)

SELECT
  database_name AS "データベース名" ,
  table_name AS "テーブル名"  ,
  ordinal_position AS "カラム順" ,
  column_name AS "カラム名"  ,
  data_type AS "データ型"  ,
  sample AS "サンプルデータ" ,
  col_info AS  "説明"  
FROM
  tmp
ORDER BY
  ordinal_position ASC
