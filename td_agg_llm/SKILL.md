---
name: td-agg-llm
description: "Treasure Data上の複数DB/Tableからデータを1つのDatabaseに集約し、ID Unificationで共通IDを付与するワークフロー(td_agg_llm)の設定・デプロイを支援する。GitHubからワークフローを取得した後の設定カスタマイズ、デプロイ、トラブルシューティングに使用する。「td_agg_llm」「LLM向けデータ集約」「ID統合ワークフロー」「データ集約WF」「LLMデータ統合」「enrichedテーブル集約」などで発動する。"
---

# td_agg_llm ワークフロー設定スキル

ユーザーがGitHubからtd_agg_llmワークフローを取得した後、対話形式で設定をカスタマイズし、Treasure Dataにデプロイするまでを支援する。

## ワークフロー概要

td_agg_llmは以下の処理を行うDigdagワークフロー:

1. **+main**: 複数DB/Tableからデータを1つの集約DBにコピー
2. **+call_unification**: ID Unification APIで共通IDを付与
3. **+push_llm_db**: `enriched_*` テーブルを集約DBにコピー
4. **+drop_tmp_table**: 中間テーブル(enriched_*以外)を削除

参考: https://advanced.cdp-academy-lab.com/id_unif/intro.html

## ファイル構成

```
td_agg_llm/
├── td_agg_llm.dig              # メインワークフロー
├── config/
│   └── agg_datas.yml            # データソース定義
├── unification_setting.yml      # ID Unification設定
└── queries/
    ├── main.sql                 # データ集約SQL
    ├── target_table.sql         # enriched_*テーブル一覧取得
    └── drop_tmp_table.sql       # 中間テーブル一覧取得
```

## 対話フロー

ユーザーにステップバイステップで以下を聞き取り、設定ファイルを生成する。

### Step 1: 基本設定

以下を確認する:
- **集約先Database名** (デフォルト: `td_llm_support`)
- **リージョン** → `td_endpoint` を決定
  - US: `api-cdp.treasuredata.com`
  - EU: `api-cdp.eu01.treasuredata.com`
  - JP: `api-cdp.ap1.treasuredata.com`
  - AP02: `api-cdp.ap02.treasuredata.com`
  - AP03: `api-cdp.ap03.treasuredata.com`
- **unification_name** (デフォルト: `agg_llm`) — `cdp_unification_<この値>` がID Unificationの出力DB名になる
- **canonical_id_name** (デフォルト: `unif_id`) — 名寄せ後の共通IDカラム名

### Step 2: データソース定義 (`config/agg_datas.yml`)

集約したいテーブルを聞き取る。各テーブルについて:
- `db`: コピー元Database
- `tbl`: コピー元Table
- `output_tbl_name`: 集約先DBでのTable名
- `where_condition`: フィルタ条件（任意。`TD_INTERVAL` 等）

**テンプレート:**
```yaml
datas:
  data1:
    db: <database名>
    tbl: <table名>
    output_tbl_name: <出力テーブル名>
    where_condition:
      #- TD_INTERVAL(time,'-360d','JST')
```

`tdx databases` や `tdx tables <db>` でDatabase/Table一覧を確認可能。ユーザーのデータを探す際に活用する。

### Step 3: ID Unification設定 (`unification_setting.yml`)

名寄せキーとテーブルマッピングを設定する:

1. **keys**: 名寄せに使うキー（email, user_id, phone 等）
   - `invalid_texts`: 無効値（空文字等）
2. **tables**: Step 2で定義した各テーブルのカラムとキーの対応
3. **canonical_ids**: 名寄せ実行設定
   - `merge_by_keys`: 使用するキーの配列
   - `merge_iterations`: マージ反復回数（デフォルト5）

**テンプレート:**
```yaml
name: ${unification_name}

keys:
  - name: <キー名>
    invalid_texts: ['']

tables:
  - database: ${td.database}
    table: <output_tbl_name>
    key_columns:
      - {column: <カラム名>, key: <キー名>}

canonical_ids:
  - name: ${canonical_id_name}
    merge_by_keys: [<キー1>, <キー2>]
    merge_iterations: 5
    incremental_merge_iterations: 3
```

`tdx describe <db>.<table>` でカラム情報を確認し、名寄せに使えるキーカラムを特定する。

### Step 4: 設定ファイル生成

聞き取り結果をもとに以下を生成:
1. `td_agg_llm.dig` の `_export` セクションを更新
2. `config/agg_datas.yml` を生成
3. `unification_setting.yml` を生成

### Step 5: デプロイ

```bash
tdx wf push --project td_agg_llm <ワークフローディレクトリ>
```

デプロイ後、Secret `td.apikey` の設定を案内:
```bash
tdx wf secret --project td_agg_llm --set "td.apikey=TD1 <APIキー>"
```

**重要:** 値には必ず先頭に `TD1 ` (半角スペース含む) を付けること。ID Unification API の内部 callback で `authorization` ヘッダーとしてそのまま使用されるため、`TD1 ` が無いと `Invalid authorization header` エラーになる。

## 重要な注意点

- ID Unification機能がアカウントで有効になっている必要がある
- `+main` はHive(Tez)エンジン、`+push_llm_db`/`+drop_tmp_table` はTrino(Presto)エンジンを使用
- データ量が多い場合は `where_condition` で期間を絞ることを推奨
- `unification_setting.yml` の `tables` セクションは `agg_datas.yml` の `output_tbl_name` と一致させる
- スケジュール実行する場合は `td_agg_llm.dig` の `schedule` セクションのコメントアウトを解除

## トラブルシューティング

| 症状 | 原因・対処 |
|---|---|
| `+call_unification` で401エラー | Secret `td.apikey` が未設定または無効 |
| callback で `Invalid authorization header` | Secret `td.apikey` の値に `TD1 ` プレフィックスが付いていない。`TD1 <APIキー>` の形式で再設定する |
| `+call_unification` で失敗 | ID Unification機能が未有効 / `td_endpoint` が間違っている |
| `enriched_*` テーブルが空 | `unification_setting.yml` のキーマッピングを確認。実際のカラム名と一致しているか |
| `+main` が遅い | `where_condition` で `TD_INTERVAL` を使って期間を絞る |
