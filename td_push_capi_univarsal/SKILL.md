---
name: capi-config-setup
description: Use when the user provides a GitHub URL for the common_push_capi workflow and wants to set up CAPI configuration interactively. Triggers on phrases like "CAPI設定", "CAPI config", "CAPIワークフローを設定", "コンバージョンAPI設定", "広告コンバージョン送信設定", or when a GitHub URL containing "common_push_capi" is mentioned. Guides the user through an interactive Q&A to generate a complete params.yml for their brand(s).
---

# CAPI Config Setup

GitHub上の `common_push_capi` ワークフローに対し、対話的にブランドごとの `config/params.yml` を生成する。

## Workflow

### Step 0: リポジトリ取得

ユーザーがGitHub URLを提示したら:

1. URLからリポジトリをクローンまたはファイルを取得する
2. `config/params.yml` と `README.md` を読み込む
3. 現在の設定内容を把握する

```bash
# リポジトリクローン例
git clone <github_url> /tmp/common_push_capi
```

もしURLが個別ファイルやディレクトリの場合は `gh` コマンドや `WebFetch` で取得する。

### Step 1: 対話的ヒアリング

以下の情報を **1問ずつ順番に** ユーザーに質問する。AskUserQuestion ツールを使い、選択肢を提示する。

#### 1-1. プラットフォーム選択

```
どの広告プラットフォームに送信しますか？
→ facebook / yahoo / line / tiktok / google_store_sales / google_enhanced_web / pinterest / snapchat
```

複数選択可。複数選択された場合はブランドごとに1エントリずつ作成する。

#### 1-2. ブランド基本情報

プラットフォームごとに:
- **brand_name**: ブランド識別子（テーブル名に使われるので英数字_のみ）
- **connector**: TDのResult Exportコネクタ名

#### 1-3. データソース設定

```
JS-SDK のデータはありますか？
→ はい (hourly + daily) / いいえ (dailyのみ)
```

- `js_enabled: true` の場合 → `log_db`, `log_tbl` を質問
- 全ブランド共通で `purchase_db`, `purchase_tbl` を質問

#### 1-4. テーブルスキーマ確認とカラム自動提案

DB名・テーブル名が確定したら、**ユーザーに許可を得た上で** 以下のコマンドを実行する:

```bash
# スキーマ確認
tdx describe {db}.{table}

# サンプルデータ取得（最新10件）
tdx query -e presto "SELECT * FROM {db}.{table} ORDER BY time DESC LIMIT 10" -f table
```

取得した結果から、以下のマッピング対象カラムを **AI が自動推定して提案** する:

**推定ロジック（カラム名とサンプル値の両方から判断）:**

| 設定項目 | カラム名のヒント | サンプル値のヒント |
|---|---|---|
| `col_order_id` / `pcol_order_id` | `transaction`, `order`, `receipt`, `tran` を含む | 英数字の一意な値 |
| `col_email` / `pcol_email` | `email`, `mail`, `address` を含む | `@`を含む文字列、またはハッシュ値(64文字hex) |
| `col_amount` / `pcol_amount` | `amount`, `price`, `revenue`, `sales`, `value` を含む | 数値 |
| `col_member_id` / `pcol_member_id` | `user`, `member`, `customer`, `cid`, `uid` を含む | IDらしい値 |
| `col_phone` | `phone`, `tel` を含む | 電話番号形式またはハッシュ値 |
| `col_country` | `country`, `region`, `geo` を含む | 国コード (JP, US等) |
| `col_user_agent` | `ua`, `user_agent`, `td_user_agent` を含む | ブラウザUA文字列 |
| `col_ip` | `ip`, `td_ip`, `remote_addr` を含む | IPアドレス形式 |
| `col_url` | `url`, `path`, `page`, `td_path`, `td_url` を含む | URL文字列 |
| `col_fbc` | `fbc`, `click_id` を含む | `fb.1.`で始まる文字列 |
| `col_fbp` | `fbp`, `pixel` を含む | `fb.1.`で始まる文字列 |
| `pcol_time` | `time`, `timestamp`, `created`, `date` を含む | UNIXタイムスタンプまたは日時文字列 |

**提案フォーマット:**

```
テーブル: {db}.{table} のスキーマを確認しました。

カラム一覧:
  - column_a (varchar)
  - column_b (bigint)
  - ...

サンプルデータから、以下のカラムマッピングを提案します:

  col_order_id  → transactionid   (理由: "transaction"を含み、値が一意なID形式)
  col_email     → hashed_email    (理由: 64文字のhex値でハッシュ済みメアドと推定)
  col_amount    → amount          (理由: 数値で売上金額と推定)
  ...
  col_phone     → (該当なし)      → "" に設定

この提案でよろしいですか？修正があれば指定してください。
```

**重要:**
- 提案はあくまで推定であり、**ユーザーの修正・上書きを常に受け付ける**
- 推定に自信がない場合は複数の候補を提示し、ユーザーに選択してもらう
- 該当カラムが見つからない場合は `""` (NULL出力) を提案する
- 購買テーブル、JS-SDKテーブル、会員マスタテーブルそれぞれに対して実行する

#### 1-5. メアド設定

スキーマ確認結果をもとに:
- メアドカラムが見つかった場合 → `has_email: true` を提案
- 見つからない場合 → `has_email: false` を提案し、会員マスタの情報を質問
  - 会員マスタも `tdx describe` でスキーマ確認し、`member_id_col`, `member_email_col` を提案

#### 1-6. フィルタ条件

サンプルデータを参考に、フィルタ条件も提案する:
- `cnv_conditions`: オーダーIDに `undefined` や空文字が混在している場合 → `"transactionid != '' AND transactionid NOT IN ('undefined')"` を提案
- `purchase_conditions`: 通常は `"1=1"`。特殊な条件があればサンプルデータから推定

#### 1-7. プラットフォーム固有設定

- **Yahoo** → `yahoo_ydn_conv_io`, `yahoo_ydn_conv_label`
- **Google (Store Sales / Enhanced Web)** → `google_conversion_action_id`
- その他 → 該当パラメータは `""` を自動設定

#### 1-8. 共通設定

```
中間テーブル・ログの出力先DBは？
→ デフォルト: capi_database

通貨コードは？
→ デフォルト: JPY
```

### Step 2: params.yml 生成

収集した情報から `config/params.yml` を生成する。

ルール:
- 存在しないカラムは必ず `""` (空文字) にする
- プラットフォームに関係ないパラメータも `""` で必ず含める（全ブランドが同じキー構造を持つこと）
- コメントで各セクションを説明する
- 設定例のコメントアウトされたブランドは削除し、実際のブランド設定のみ出力する

### Step 3: 確認・修正

生成した `params.yml` をユーザーに提示し、修正点がないか確認する。
修正があれば対応し、最終確認後にファイルを書き出す。

### Step 4: デプロイガイド

```bash
cd common_push_capi
tdx wf push
tdx wf run daily_push_capi
```

## ヒアリングのコツ

- **スキーマ確認を積極的に行う**: DB・テーブル名が確定したら必ず `tdx describe` と サンプルクエリを実行して提案の精度を上げる
- **提案は修正前提で提示する**: 「この提案でよろしいですか？修正があれば指定してください」と必ず確認する
- **1回の質問で多くを聞きすぎない**: 3〜4項目ずつグルーピングして質問する
- **デフォルト値を提示する**: ユーザーが迷わないように典型的な値を示す
- **選択肢で絞り込む**: 自由入力より選択肢を優先する
- **複数ブランドの場合**: 1ブランド目を詳細に設定し、2ブランド目以降は差分のみ質問する

## Edge Cases

- ユーザーが GitHub URL ではなくローカルパスを指定した場合 → そのパスの `config/params.yml` を直接編集する
- 既存の params.yml に追記したい場合 → 既存のブランド設定を保持しつつ新規ブランドを追加
- `tdx describe` が権限エラーで失敗した場合 → ユーザーにカラム名を手動で入力してもらう
- 同じブランドを複数プラットフォームに送信したい場合 → brand_name を `{brand}_{platform}` の形式で区別する
