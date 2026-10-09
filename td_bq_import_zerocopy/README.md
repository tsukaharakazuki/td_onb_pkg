# このWorkflowについて
BigQueryのデータを **Live Connect Zero-Copy（フェデレーテッドクエリ）** でTreasure Dataに取り込み、日次更新するWFのサンプルです。
コネクタ（`td_load>` + GCS経由）を使う [td_bq_import](../td_bq_import) と違い、GCSバケットや一時データセットは不要で、Trinoクエリ（`INSERT INTO`）だけで取り込みます。

- ドキュメント: [Live Connect Zero Copy With Google BigQuery](https://docs.treasure.ai/products/customer-data-platform/integration-hub/zero-copy/live-connect-zero-copy-with-google-big-query)
- 取り込み定義（SQL・出力先・モード・分割方法）はすべて `config/zerocopy_setting.yml` にまとめています。テーブルを増やすときはこのファイルに1ブロック追加するだけです。

# 事前準備
1. Zero-Copyはデフォルトで無効です。CSM/Supportに有効化を依頼してください
2. Integration Hub で BigQuery の Authentication を作成
3. **New Zero-Copy** ソースを作成（JSON keyfileを指定）。ソース名がTrinoのカタログ名になります
   - `bigquery_` で始まり64文字以内
   - 作成・変更の反映に最大5分かかります
4. Data Workbench（Trino）で疎通確認
   ```sql
   SELECT * FROM bigquery_xxx.bq_dataset.bq_table LIMIT 10
   ```

# ファイル構成
```
td_bq_import_zerocopy/
├── td_bq_import_zerocopy.dig        # メインWF（full / incremental / split の3モード）
├── subflow/load_unit.dig            # 1ロード単位（=フェデレーテッドクエリ1本）の削除＋INSERT
├── config/
│   ├── common_params.yml            # カタログ名など共通設定
│   └── zerocopy_setting.yml         # 取り込み定義（ここを編集する）
├── queries/
│   ├── load.sql                     # 設定のqueryを包んで td_load_key / time を付与
│   ├── split_list.sql               # 分割リスト（split_from / split_to）を生成
│   ├── check_load_key_column.sql
│   └── delete_by_load_key.sql
└── bq_size_check/                   # 事前のデータ量確認用（BigQueryコンソールで実行）
```

# 取り込みモード
| モード | 用途 | 1回のWF実行で発行するBQクエリ |
|---|---|---|
| `full_import` | 10GB未満のマスタ等を洗い替え（`replace`）/追記（`append`） | 1本 |
| `incremental_import` | 日次の差分（対象日 = `session_date - offset_days` の1日分）を追記 | 1本 |
| `split_import` | **10GBを超えるテーブル**。分割キー単位で `td_for_each>` ループ | 分割数分 |

### query で使えるプレースホルダ
| プレースホルダ | 置換される値 |
|---|---|
| `__CATALOG__` | `common_params.yml` の `zc.catalog` |
| `__FROM__` | incremental: 対象日（`YYYY-MM-DD`）/ split: `split_from` |
| `__TO__` | incremental: 対象日の翌日 / split: `split_to` |

### 自動付与されるカラム
- `td_load_key`：ロード単位のキー（full = session_date / incremental = 対象日 / split = split_from）。再実行時は同じキーのデータを削除してから追記するため、重複しません
- `time`：`time_expr`（例: `TO_UNIXTIME(updated_at)`）から生成。省略時は `session_unixtime`。**query 側で `time` カラムを SELECT しないでください**

# ⚠ 10GB制限と分割設計（重要）
フェデレーテッドクエリは **1クエリでBigQueryから読み込むデータ量が10GBを超えると中断** されます（現在は段階的に有効化中。上限の変更はSupportへの依頼が必要）。
そのため、取り込み前に必ずデータ量を確認し、10GBを超えるテーブルは `split_import` で分割してください。

1. **サイズ確認**（BigQueryコンソールで `bq_size_check/` のSQLを実行）
   - `01_table_size.sql`：テーブル単位のサイズ。7GB以上（余裕をみた目安）なら split を検討
   - `02_partition_size.sql`：パーティションテーブルの日/月単位のサイズ → 分割粒度を決める
   - `03_split_key_size.sql`：非パーティションテーブルのID等のレンジ別サイズ見積もり
2. **分割キーの選定**：BQ側で範囲を一意に特定できるカラムを使う
   - 第一候補：パーティション列（日付/タイムスタンプ）・クラスタリング列
   - 次点：連番の数値ID（レンジで分割）
   - 分割は `>= __FROM__ AND < __TO__` の半開区間にして、取りこぼしと重複を防ぐ
3. **プッシュダウンが効く書き方にする**：分割キーに関数（`CAST`・`DATE()`・`MOD` 等）をかけず、リテラルと直接比較する。関数をかけるとBQ側でフィルタされず、全件読み込みになり10GBを超える恐れがあります
4. **SELECTするカラムを絞る**：BigQuery Storage APIは列指向なので、必要なカラムだけにすると読み込み量が減ります
5. **分割リストは `SEQUENCE` で作る**：`split_list_query` で BigQuery を読まずに分割リストを作れます（設定例参照）

# その他の注意点
- 大文字を含む dataset / table / column はアクセスできず、`SHOW TABLES` にも出ません（クォートしても不可）。BQ側で小文字名のコピー（テーブルクローン等）を作成してください
- フェデレーテッドクエリはTrinoのみ対応（Hive不可）
- Zero-Copy Configはアカウント全体で最大50個
- BQの `DATE` / `NUMERIC` / `STRUCT` / `ARRAY` 等は、TDで扱いやすい型に `CAST`（VARCHAR / DOUBLE / JSON 等）しておくと安全です

# 実行
```bash
td wf push td_bq_import_zerocopy
td wf start td_bq_import_zerocopy td_bq_import_zerocopy --session now
```
初回は `split_import` の `split_list_query` を数行に絞って動作確認してから全期間を流すことを推奨します。
