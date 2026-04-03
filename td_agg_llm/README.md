# td_agg_llm - LLM向けデータ集約 & ID統合ワークフロー

Treasure Data上の複数Database/Tableからデータを1つのDatabaseに集約し、[ID Unification](https://advanced.cdp-academy-lab.com/id_unif/intro.html)で共通IDを付与するDigdagワークフローです。

LLMがデータを横断的に扱えるよう、散在するテーブルを統合し、名寄せ済みのデータセットを作成します。

---

## 処理フロー

```
1. +main             : 各テーブルからデータを集約DBへコピー
2. +call_unification : ID Unification API を呼び出し、共通IDを付与
3. +push_llm_db      : enriched_* テーブルを集約DBへコピー
4. +drop_tmp_table   : 集約DB内の中間テーブル(enriched_* 以外)を削除
```

### 詳細

| ステップ | 内容 |
|---|---|
| **+main** | `config/agg_datas.yml` で定義した各データソースから `queries/main.sql` を実行し、集約先DB (`td_llm_support`) にテーブルを作成 |
| **+call_unification** | Treasure Data の ID Unification API を HTTP 呼び出し。`unification_setting.yml` の設定に基づき、キー(email, uid等)でレコードを名寄せし、共通ID (`unif_id`) を付与 |
| **+push_llm_db** | ID Unification の出力DB (`cdp_unification_<name>`) から `enriched_*` テーブルを集約DBへコピー |
| **+drop_tmp_table** | 集約DB内の `enriched_*` 以外のテーブル（中間テーブル）を削除してクリーンアップ |

---

## ファイル構成

```
td_agg_llm/
├── td_agg_llm.dig              # メインワークフロー定義
├── config/
│   └── agg_datas.yml            # 集約するデータソースの定義
├── unification_setting.yml      # ID Unification の設定
└── queries/
    ├── main.sql                 # データ集約SQL
    ├── target_table.sql         # enriched_* テーブル一覧取得SQL
    └── drop_tmp_table.sql       # 中間テーブル一覧取得SQL
```

---

## セットアップ

### 1. `config/agg_datas.yml` - データソース定義

集約したいデータソースを定義します。

```yaml
datas:
  data1:
    db: database1          # 元のDatabase名
    tbl: table1            # 元のTable名
    output_tbl_name: output_table1  # 集約DBでのTable名
    where_condition:
      #- TD_INTERVAL(time,'-360d','JST')  # フィルタ条件（任意）
  data2:
    db: database2
    tbl: table2
    output_tbl_name: output_table2
    where_condition:
```

| パラメータ | 説明 |
|---|---|
| `db` | コピー元のDatabase名 |
| `tbl` | コピー元のTable名 |
| `output_tbl_name` | 集約先DBに作成するTable名 |
| `where_condition` | WHERE句に追加するフィルタ条件のリスト（省略可）。`TD_INTERVAL` 等で期間を絞ることで処理時間を短縮できます |

### 2. `unification_setting.yml` - ID Unification 設定

名寄せのキーとテーブルのマッピングを定義します。

```yaml
name: ${unification_name}

keys:
  - name: email           # 名寄せキー1
    invalid_texts: ['']
  - name: uid             # 名寄せキー2
    invalid_texts: ['']

tables:
  - database: ${td.database}
    table: output_table1
    key_columns:
      - {column: email, key: email}
      - {column: user_id, key: uid}
  - database: ${td.database}
    table: output_table2
    key_columns:
      - {column: email, key: email}

canonical_ids:
  - name: ${canonical_id_name}
    merge_by_keys: [email, uid]
    merge_iterations: 5
```

**設定のポイント:**
- `keys`: 名寄せに使うキーを定義。`invalid_texts` で空文字等の無効値を除外
- `tables`: 各テーブルのどのカラムがどのキーに対応するかをマッピング
- `canonical_ids`: 名寄せの実行設定。`merge_by_keys` で使用するキーを指定

> 参考: [ID Unification ドキュメント](https://advanced.cdp-academy-lab.com/id_unif/intro.html)

### 3. `td_agg_llm.dig` - ワークフロー設定

```yaml
_export:
  td:
    database: td_llm_support      # 集約先Database名
  td_endpoint: api-cdp.treasuredata.com  # TD API エンドポイント
  unification_name: agg_llm       # ID Unification名
  canonical_id_name: unif_id      # 共通IDのカラム名
```

| パラメータ | 説明 |
|---|---|
| `td.database` | 集約先のDatabase名 |
| `td_endpoint` | Treasure Data APIエンドポイント。リージョンに応じて変更 |
| `unification_name` | ID Unificationの名前。`cdp_unification_<この値>` というDBが作成されます |
| `canonical_id_name` | 名寄せ後に付与される共通IDのカラム名 |

**リージョン別エンドポイント:**
| リージョン | エンドポイント |
|---|---|
| US | `api-cdp.treasuredata.com` |
| EU | `api-cdp.eu01.treasuredata.com` |
| JP | `api-cdp.ap1.treasuredata.com` |
| AP02 | `api-cdp.ap02.treasuredata.com` |
| AP03 | `api-cdp.ap03.treasuredata.com` |

### 4. Secretの設定

ワークフローのSecret に Treasure Data APIキーを設定してください。

- Secret名: `td.apikey`
- 値: `TD1 <あなたのAPIキー>`

> **重要:** 値には必ず先頭に `TD1 ` (半角スペース含む) を付けてください。
> ID Unification API の内部 callback で `authorization` ヘッダーとしてそのまま使用されるため、`TD1 ` プレフィックスが無いと `Invalid authorization header` エラーで失敗します。
>
> ```
> # 正しい例
> TD1 1234/abcdefghijklmnopqrstuvwxyz
>
> # 間違い例（TD1 が無い）
> 1234/abcdefghijklmnopqrstuvwxyz
> ```

---

## スケジュール実行

定期実行する場合は `td_agg_llm.dig` のコメントアウトを解除してください。

```yaml
schedule:
  cron>: 0 18 * * *  # 毎日18:00 (JST)
```

---

## 注意事項

- ID Unification の実行には、対象アカウントで **ID Unification機能が有効** になっている必要があります
- `+main` ステップでは **Hive (Tez)** エンジンを使用します
- `+push_llm_db` / `+drop_tmp_table` ステップでは **Trino (Presto)** エンジンを使用します
- 集約するデータ量が多い場合は `where_condition` で期間を絞ることを推奨します
- ID Unification 実行中は `cdp_unification_<unification_name>` DBが一時的に作成されます

---

## ライセンス

このワークフローはTreasure Dataのプロジェクトテンプレートとして提供されています。
