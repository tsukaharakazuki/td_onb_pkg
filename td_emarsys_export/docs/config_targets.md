# 送信データ定義（targets）詳細設定

`config/sftp.yml` と `config/webdav.yml` の `targets` には、1 回の実行で送信するデータを複数定義できます。各キーが `for_each>` で展開され、同じタスク（`+sftp_send` / `+webdav_query` → `+webdav_upload`）を変数を切り替えて実行します。

項目は SFTP / WebDAV で共通です。

## 仕組み

```yaml
targets:
  contacts:      # ← for_each の 1 周目（target = "contacts"）
    ...
  sales_items:   # ← 2 周目（target = "sales_items"）
    ...
```

- dig / SQL からは `${targets[target].キー名}` で参照します。
- `+sftp` / `+webdav` はそれぞれのスコープで自分の config を読み込むため、同じ `targets` という名前でも互いに干渉しません。そのため SQL は両方式で共通の 1 本（`query/export_select.sql`）で済みます。
- 実行順は YAML の記載順です（直列）。
- データを追加するときは、キーを追加するだけで dig の変更は不要です。

## パラメータ一覧

| キー | 型 | 必須 | 例 | 説明 |
|------|----|------|----|------|
| `enabled` | boolean | ○ | `true` | `false` のターゲットはスキップ |
| `query_file` | string | ○ | `export_select` | `query/` 配下の SQL ファイル名（拡張子なし） |
| `engine` | string | ○ | `presto` | `presto`（Trino）/ `hive` |
| `source_db` | string | ○ | `cdp_audience_123` | 抽出元 DB。`td>` の `database` にも使用 |
| `source_table` | string | ○ | `customers` | 抽出元テーブル |
| `columns` | string | ○ | 下記参照 | SELECT 句。`AS` 名が CSV のヘッダー＝Emarsys 側の項目名になる |
| `where` | string | ○ | `TD_INTERVAL(time, '-1d', 'JST')` | WHERE 句。条件不要なら `"1 = 1"` |
| `file_prefix` | string | ○ | `contacts` | ファイル名の接頭辞 → `{file_prefix}_{yyyyMMdd}.csv` |
| `delimiter` | string | ○ | `","` | 区切り文字。`","` / `"\t"` / `"|"` |

### 各キーの補足

#### key名（`contacts` など）
- for_each の識別子でログにも表示されます。英小文字・数字・アンダースコアを推奨。
- ファイル名には使われません（ファイル名は `file_prefix`）。

#### query_file
- 通常は汎用 SQL の `export_select` を使います。
- JOIN や集計など `columns` / `where` で表現できない処理は、`query/` に SQL を追加して指定します。追加 SQL 内でも `${targets[target].source_db}` などを参照できます。

```sql
-- query/contacts_with_points.sql の例
SELECT
    c.customer_id AS external_id
    , c.email
    , p.point_balance
FROM ${targets[target].source_db}.${targets[target].source_table} c
LEFT JOIN ${targets[target].source_db}.points p
    ON c.customer_id = p.customer_id
WHERE ${targets[target].where}
```

#### columns
- YAML のブロック記法 `>-` を使うと複数行で書けます（改行はスペースに変換されます）。
- `AS` 名は Emarsys 自動インポートのフィールドマッピングで使います。サンプル CSV と一致させてください。
- Trino の予約語（`order`, `timestamp` など）を列名にする場合はダブルクォートで囲みます（`AS "order"`）。

```yaml
columns: >-
  customer_id AS external_id
  , email
  , DATE_FORMAT(FROM_UNIXTIME(birthday_unixtime), '%d.%m.%Y') AS birth_date
```

#### where
- 差分送信の場合は `TD_INTERVAL` / `TD_TIME_RANGE` で `time` を絞り込みます（パーティションプルーニングが効き高速）。
- 全件送信の場合は `"1 = 1"`。
- 文字列リテラルはシングルクォート、YAML 全体はダブルクォートで囲みます。

| 用途 | 例 |
|------|----|
| 前日分 | `"TD_INTERVAL(time, '-1d', 'JST')"` |
| 直近 1 時間 | `"TD_INTERVAL(time, '-1h', 'JST')"` |
| 更新日時カラムで前日分 | `"updated_at >= CAST(CURRENT_DATE - INTERVAL '1' DAY AS VARCHAR)"` |
| 全件 | `"1 = 1"` |

#### file_prefix
- Emarsys 自動インポートのファイル名パターン（例: `contacts_*.csv`）と一致させます。大文字小文字を区別します。
- 使用可能文字は英数字・アンダースコア・ハイフンを推奨。

#### delimiter
- Emarsys 自動インポートで指定した区切り文字と一致させます。
- タブは `"\t"`（ダブルクォート必須）。

## Emarsys データ別のポイント

### 連絡先（contacts）

- 一意の外部 ID 列が必要です。推測できない英数字の永続 ID を推奨（メールアドレスは必要時のみ）。
- カスタムフィールドは事前に Emarsys で作成しておきます。
- 日付は自動インポートで指定した形式（例: `DD.MM.YYYY`）に合わせます。
- 小数点はピリオド。
- オプトイン（フィールド ID 31）の FALSE → TRUE はインポートでは変更できません（API か手動のみ）。

```yaml
contacts:
  enabled: true
  query_file: export_select
  engine: presto
  source_db: "cdp_audience_123"
  source_table: "customers"
  columns: >-
    customer_id AS external_id
    , email
    , last_name
    , first_name
  where: "TD_INTERVAL(time, '-1d', 'JST')"
  file_prefix: "contacts"
  delimiter: ","
```

### 販売データ（sales_items / Smart Insight）

- ファイル名は `sales_items` で始まり `.csv` で終わる必要があります → `file_prefix: "sales_items"`。
- ヘッダーは小文字。必須列: `item`, `price`, `order`, `timestamp`, `customer`（または `email`）, `quantity`。`customer` と `email` は混在させない。
- 列順はオンボーディング時の定義どおりに固定。カスタム列は `i_` / `f_` / `t_` / `s_` 接頭辞を付けて末尾に追加。
- `timestamp` は ISO 8601（例: `2026-10-11T12:18:51Z`）。
- 増分アップロードで重複は削除されないため、`where` で期間が重複しないようにします。

```yaml
sales_items:
  enabled: true
  query_file: export_select
  engine: presto
  source_db: "ec_db"
  source_table: "order_items"
  columns: >-
    item_id AS item
    , CAST(unit_price * quantity AS DOUBLE) AS price
    , order_id AS "order"
    , TO_ISO8601(FROM_UNIXTIME(order_time)) AS "timestamp"
    , customer_id AS customer
    , quantity
  where: "TD_INTERVAL(time, '-1d', 'JST')"
  file_prefix: "sales_items"
  delimiter: ","
```

## よくあるミス

| 症状 | 原因 |
|------|------|
| SQL 構文エラー | `columns` の先頭・末尾の余分なカンマ、予約語のクォート漏れ |
| for_each が 0 周 | `targets` のインデント誤り |
| 想定外のデータ量 | `where` の時間条件漏れ（全件送信になる） |
| Emarsys で項目が紐付かない | `AS` 名とフィールドマッピングの不一致 |

## 関連ドキュメント

- [config/common.yml 詳細設定](config_common.md)
- [config/sftp.yml 詳細設定](config_sftp.md)
- [config/webdav.yml 詳細設定](config_webdav.md)
