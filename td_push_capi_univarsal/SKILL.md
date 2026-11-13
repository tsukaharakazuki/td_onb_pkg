---
name: capi-config-setup
description: Use when the user provides a GitHub URL for the td_push_capi_univarsal (or legacy common_push_capi) CAPI workflow and wants to set up CAPI configuration interactively. Triggers on phrases like "CAPI設定", "CAPI config", "CAPIワークフローを設定", "コンバージョンAPI設定", "広告コンバージョン送信設定", "OpenAI CAPI", or when a GitHub URL containing "td_push_capi_univarsal" or "common_push_capi" is mentioned. Guides the user through an interactive Q&A to generate a complete params.yml for their brand(s), with dry-run-first deployment.
---

# CAPI Config Setup

GitHub上の `td_push_capi_univarsal` ワークフロー（旧称 `common_push_capi`）に対し、対話的にブランドごとの `config/params.yml` を生成する。

## Workflow

### Step 0: リポジトリ取得

ユーザーがGitHub URLを提示したら:

1. URLからリポジトリをクローンまたはファイルを取得する
2. `config/params.yml` と `README.md` を読み込む
3. 現在の設定内容（`common` と `brand`）を把握する

```bash
# リポジトリクローン例
git clone <github_url> /tmp/td_push_capi_univarsal
```

もしURLが個別ファイルやディレクトリの場合は `gh` コマンドや `WebFetch` で取得する。

### Step 1: 対話的ヒアリング

以下の情報を **1問ずつ順番に** ユーザーに質問する。AskUserQuestion ツールを使い、選択肢を提示する。

#### 1-1. プラットフォーム選択

```
どの広告プラットフォームに送信しますか？
→ facebook / yahoo / line / tiktok / google_store_sales / google_enhanced_web / google_data_manager_for_conversions / pinterest / snapchat / x / openai
```

複数選択可。複数選択された場合はブランドごとに1エントリずつ作成する。

**Yahoo と LINE は別ブランドにする。** どちらも同じコネクタ種別 `yahoo_conversion_v2` を使うが、`tag_id` / `channel_id` / `event_type` などはブランドごとに別々に設定する。

**Google Data Manager for Conversions を選択した場合の注意:** Integration Hub のオーディエンスリスト用「Google Data Manager」ではなく、「Google Data Manager for Conversions」OAuthコネクタを作成する。現在の共通ベースが送る識別子はURL内のGoogle Click ID、email、IPで、`STORE_SALES` はemail必須・日次WFのみ。Google側のallowlist登録と `store_id` も必要。不正行を送信済みにしないため `google_dm_skip_invalid_records: false` を推奨する。`google_dm_waiting_for_request_status` は毎時処理では `false`、最終処理結果まで同期確認する場合のみ `true` とする。

**X (Twitter) を選択した場合の注意:** X にはTDのResult Exportコネクタが存在しないため、`py>` オペレーターで直接 X Ads API (Conversion API) へOAuth1.0a署名付きリクエストを送信する。`connector` は不要（`""` のままでよい）。

**OpenAI を選択した場合の注意:** OpenAI Conversion API Export のコネクタを作成する。テンプレートが対応するイベント種別は `order_created` のみ。

#### 1-2. ブランド基本情報

プラットフォームごとに:
- **brand_name**: ブランド識別子（テーブル名に使われるので英数字_のみ）
- **connector**: TDのコネクタ名（yahoo / line は `yahoo_conversion_v2` 種別、openai は OpenAI Conversion API Export 種別、X は `""`）

認証情報（Yahoo の `tag_access_token`、OpenAI の Conversions API Key、LINE のアクセストークン）はユーザーに params.yml へ書かせない。Integration Hub のコネクタ側で設定するよう案内する。

#### 1-3. データソース設定（`common`）

```
JS-SDK のデータはありますか？
→ はい (hourly + daily) / いいえ (dailyのみ)
```

- `js_enabled: true` の場合 → `log_db`, `log_tbl` を質問
- 全ブランド共通で `purchase_db`, `purchase_tbl` を質問（日次送信を使う場合）

#### 1-4. テーブルスキーマ確認とカラム自動提案

DB名・テーブル名が確定したら、**ユーザーに許可を得た上で** 以下のコマンドを実行する（SELECT のみ）:

```bash
# スキーマ確認
tdx describe {db}.{table}

# サンプルデータ取得（最新10件）
tdx query -d {db} --limit 10 "SELECT * FROM {table} ORDER BY time DESC LIMIT 10"
```

- 時間カラムが `time` でない場合は、そのテーブルの時間カラム名に合わせる
- 既定以外のプロファイルを使う場合は `tdx -p <profile> ...` を各コマンドに付ける。`tdx use profile` などで既定プロファイルを切り替えない
- `tdx describe` が権限エラーで失敗した場合 → ユーザーにカラム名を手動で入力してもらう

取得した結果から、以下のマッピング対象カラムを **AI が自動推定して提案** する:

**推定ロジック（カラム名とサンプル値の両方から判断）:**

| 設定項目 | カラム名のヒント | サンプル値のヒント |
|---|---|---|
| `col_order_id` / `pcol_order_id` | `transaction`, `order`, `receipt`, `tran` を含む | 英数字の一意な値（Yahoo / OpenAI は安定した一意値） |
| `col_email` / `pcol_email` | `email`, `mail`, `address` を含む | `@`を含む文字列、またはハッシュ値(64文字hex) |
| `col_amount` / `pcol_amount` | `amount`, `price`, `revenue`, `sales`, `value` を含む | 数値（小数がある場合も保持される） |
| `col_member_id` / `pcol_member_id` | `user`, `member`, `customer`, `cid`, `uid` を含む | IDらしい値 |
| `col_phone` / `pcol_phone` | `phone`, `tel` を含む | 電話番号形式またはハッシュ値（国際形式が望ましい） |
| `col_country` | `country`, `region`, `geo` を含む | 国コード (JP, US等) |
| `col_user_agent` | `ua`, `user_agent`, `td_user_agent` を含む | ブラウザUA文字列 |
| `col_ip` | `ip`, `td_ip`, `remote_addr` を含む | IPアドレス形式 |
| `col_url` / `pcol_url` | `url`, `path`, `page`, `td_path`, `td_url` を含む | URL文字列（OpenAI の web では必須） |
| `col_referrer_url` / `pcol_referrer_url` | `referrer`, `referer`, `ref` を含む | URL文字列 |
| `col_fbc` | `fbc`, `click_id` を含む | `fb.1.`で始まる文字列 |
| `col_fbp` | `fbp`, `pixel` を含む | `fb.1.`で始まる文字列 |
| `col_ly_su` / `pcol_ly_su` | `ly_su` を含む | `タイムスタンプ.ID` 形式（`_ly_su` Cookie） |
| `col_ly_c` / `pcol_ly_c` | `ly_c` を含む | `_ly_c` Cookie 由来、またはURLパラメータ由来（URL由来は先頭にタイムスタンプが必要） |
| `col_ly_r` / `pcol_ly_r` | `ly_r` を含む | `タイムスタンプ.乱数` 形式（`_ly_r` Cookie） |
| `col_line_uid` / `pcol_line_uid` | `line_uid`, `lineuid` を含む | LINE のユーザーID |
| `col_ifa` / `pcol_ifa` | `ifa`, `idfa`, `aaid`, `gaid` を含む | 広告ID（Yahoo のみに使う。OpenAI へは送らない） |
| `col_obref` | `obref` を含む | OpenAI の obref 値（測定同意がある場合のみ使う。毎時のみ） |
| `col_oppref` | `oppref` を含む | OpenAI の oppref 値（毎時のみ） |
| `pcol_time` | `time`, `timestamp`, `created`, `date` を含む | TDのUnix秒タイムスタンプ（日時文字列は事前変換が必要） |

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

#### 1-5. メアド・会員マスタ設定

スキーマ確認結果をもとに:
- メアドカラムが見つかった場合 → `js_has_email` / `purchase_has_email` を `true` に提案
- 見つからない場合 → `false` を提案し、会員マスタの情報を質問
  - 会員マスタも `tdx describe` でスキーマ確認し、`member_id_col`, `member_email_col` を提案
  - `member_db` / `member_tbl` / `member_id_col` / `member_email_col` の4つがすべて揃わない場合は JOIN しない（メアドは NULL）。ユーザーに会員マスタがないことを確認する
- 識別子だけで送るデータ（メアドなし）の場合は、`col_ly_*` / `pcol_ly_*` / `col_line_uid` / `pcol_line_uid` の候補を確認する。Yahoo / LINE は識別子が1つ以上ある行だけ送信される

#### 1-6. フィルタ条件

サンプルデータを参考に、フィルタ条件も提案する:
- `cnv_conditions`: オーダーIDに `undefined` や空文字が混在している場合 → `"transactionid != '' AND transactionid NOT IN ('undefined')"` を提案
- `purchase_conditions`: 通常は `"1=1"`。特殊な条件があればサンプルデータから推定

#### 1-7. プラットフォーム固有設定

- **Yahoo / LINE（`yahoo_conversion_v2`）** → 次の項目を質問する（ブランドごとに別々）:
  - `tag_id`（広告タグID。必須）
  - `channel_id`（`line_uid` を送る場合のみ必須。送らないなら `""`）
  - `event_type`（既定 `purchase`。Yahoo が受け付ける値: `page_view` / `view_listing` / `view_product` / `view_cart` / `add_cart` / `search` / `check_out` / `purchase` / `generate_lead` / `login` / `reservation` / `sign_up` / `payment_info` / `add_wishlist`）
  - `event_snippet_id`（任意）、`custom_label`（任意）
  - `test_flag`（既定 `false`。テスト送信のみ `true`。`true` の送信は送信ログに記録されない）
  - `skip_invalid_records`（既定 `false`）、`stop_on_batch_failure`（既定 `true`）
  - 認証情報（`tag_access_token`）は params.yml に書かず、コネクタ側で設定するよう案内する
- **OpenAI** → 次の項目を質問する:
  - `openai_pixel_id`（必須）
  - `openai_action_source`（毎時データ。既定 `web`。`source_url` が必要）
  - `openai_daily_action_source`（日次データ。実際の発生元に合わせて `offline` または `web`。`web` の場合は `pcol_url` が必須）
  - `openai_event_type`（`order_created` 固定）
  - `openai_amount_multiplier`（JPY は `1`、USD は `100`。他通貨は ISO 4217 の最小単位を確認して明示的に設定する。推測で `100` にしない。0 以下は不可）
  - `openai_skip_invalid_records`（既定 `false`）
  - `col_obref` は測定の同意が取れている場合のみ設定する。同意状況を推測して既定値を入れない
  - Conversions API Key はコネクタ側で設定するよう案内する
- **Google (Store Sales / Enhanced Web)** → `google_customer_id`, `google_conversion_action_id`
- **Google Data Manager for Conversions** → `google_dm_conversion_type`, `google_dm_operating_account_id`, `google_dm_login_account_id`（MCC経由時のみ）, `google_dm_conversion_action_id`, `google_dm_event_source`（OFFLINE時）, `google_dm_store_id`（STORE_SALES時）, 同意設定、無効レコード・ステータス待機設定
- **X (Twitter)** → `x_pixel_id`（Events Managerで発行）, `x_event_id`（Events Managerで作成した固定イベントID。注文IDではない点に注意）, `x_consumer_key`, `x_consumer_secret`, `x_access_token`, `x_access_token_secret`（Developer Portal で発行するOAuth1.0a認証情報）
- **その他** → 該当パラメータは `""` を自動設定

#### 1-8. 共通設定

```
中間テーブル・ログの出力先DBは？
→ `common.database` の値（例: `td_capi_universal`。`params.yml` にそのまま記載）

通貨コードは？
→ デフォルト: JPY
```

通貨を USD などに変える場合は、OpenAI の `openai_amount_multiplier` と組み合わせを必ず確認する。

### Step 2: params.yml 生成

収集した情報から `config/params.yml` を生成する。

ルール:
- 存在しないカラムは必ず `""` (空文字) にする
- プラットフォームに関係ないパラメータも `""` で必ず含める（全ブランドが同じキー構造を持つこと）
- コメントで各セクションを説明する
- 設定例のコメントアウトされたブランドは削除し、実際のブランド設定のみ出力する
- 認証情報（Yahoo の `tag_access_token`、OpenAI の Conversions API Key、LINE のアクセストークン）は params.yml に書かない
- 旧キー（`yahoo_ydn_conv_io`, `yahoo_ydn_conv_label`, `yahoo_app_id`, `line_tag_id`, `line_access_token`）は出力しない。既存の params.yml にあれば移行先に置き換える（移行表は README.md 参照）
- `brand` の `platform` は許可リストの値のみ使う（それ以外はワークフローが停止する）

構造:

```yaml
common:                 # 全ブランド共通: データソース・カラム・フィルタ
  database: ...
  currency: JPY
  timezone: Asia/Tokyo
  js_enabled: ...
  js_has_email: ...
  purchase_has_email: ...
  # カラムマッピング（col_* / pcol_*。存在しなければ ""）
  ...

brand:                  # 送信先ごと（1 ブランド = 1 送信先）
  - brand_name: ""
    platform: ""
    connector: ""
    # Yahoo / LINE 用（platform: yahoo / line のときだけ使う。それ以外は ""）
    tag_id: ""
    channel_id: ""
    event_type: ""
    event_snippet_id: ""
    test_flag: false
    custom_label: ""
    skip_invalid_records: false
    stop_on_batch_failure: true
    # OpenAI 用
    openai_pixel_id: ""
    openai_action_source: ""
    openai_daily_action_source: ""
    openai_event_type: ""
    openai_amount_multiplier: ""
    openai_skip_invalid_records: false
    # Google / TikTok / X 用（各 platform のときだけ使う。それ以外は ""）
    google_customer_id: ""
    google_conversion_action_id: ""
    tiktok_event_data_source: ""
    tiktok_event_source_id: ""
    google_dm_conversion_type: ""
    google_dm_operating_account_id: ""
    google_dm_login_account_id: ""
    google_dm_conversion_action_id: ""
    google_dm_event_source: ""
    google_dm_store_id: ""
    google_dm_ad_user_data_consent: CONSENT_GRANTED
    google_dm_ad_personalization_consent: CONSENT_GRANTED
    google_dm_skip_invalid_records: false
    google_dm_waiting_for_request_status: false
    x_pixel_id: ""
    x_event_id: ""
    x_consumer_key: ""
    x_consumer_secret: ""
    x_access_token: ""
    x_access_token_secret: ""
```

`brand` の各エントリは、上記のキーを `""` 以外の値だけ埋めて出力する（キーの欠落は避ける）。

### Step 3: 確認・修正

生成した `params.yml` をユーザーに提示し、修正点がないか確認する。
修正があれば対応し、最終確認後にファイルを書き出す。

確認時に必ず伝えること:
- 送信先ごとの対象（ブランド・プラットフォーム）
- Yahoo / LINE の `channel_id` と `line_uid` の組み合わせ（`line_uid` を送るなら `channel_id` 必須）
- OpenAI の `openai_amount_multiplier` と `common.currency` の組み合わせ
- `skip_invalid_records: false` と `stop_on_batch_failure: true` の推奨理由（送信ログとの整合）

### Step 4: デプロイガイド（dry-run 必須・承認制）

```bash
# 1. プロジェクトフォルダへ移動
cd td_push_capi_univarsal

# 2. 変更内容の確認のみ（アップロードしない）
tdx wf push --dry-run

# 3. 承認後にアップロード（--skip-validation は使わない）
tdx wf push

# 4. スケジュールの状態を確認（無効のままであることを確認）
tdx wf schedule list common_push_capi.hourly_push_capi
tdx wf schedule list common_push_capi.daily_push_capi

# 5. 実行の dry-run（送信はしない）
tdx wf run common_push_capi.daily_push_capi --dry-run

# 6. 承認を得た後に 1 回だけ実行
tdx wf run common_push_capi.daily_push_capi
```

- **dry-run を省略しない**。dry-run の結果から、送信先・ブランド・想定件数を説明する。件数が取得できない場合は「件数不明」と明記してから承認を得る
- **承認なしに `tdx wf run` を実行しない**。承認なしにスケジュールを有効化しない（`tdx wf schedule enable` は承認後のみ）
- `tdx wf push --backfill` は承認なしに使わない
- `--param` で動作を切り替えない（切り替えは `params.yml` で行う）
- ワークフロー名は `project.workflow` 形式（`common_push_capi.daily_push_capi`）。フォルダ名は `td_push_capi_univarsal` だが、TD 上のプロジェクト名は `tdx.json` の `workflow_project` のまま

## ヒアリングのコツ

- **スキーマ確認を積極的に行う**: DB・テーブル名が確定したら必ず `tdx describe` と サンプルクエリを実行して提案の精度を上げる
- **提案は修正前提で提示する**: 「この提案でよろしいですか？修正があれば指定してください」と必ず確認する
- **1回の質問で多くを聞きすぎない**: 3〜4項目ずつグルーピングして質問する
- **デフォルト値を提示する**: ユーザーが迷わないように典型的な値を示す
- **選択肢で絞り込む**: 自由入力より選択肢を優先する
- **複数ブランドの場合**: 1ブランド目を詳細に設定し、2ブランド目以降は差分のみ質問する
- **Yahoo と LINE は別ブランド**: 同じ注文データを送る場合でも、`tag_id` / `channel_id` / `event_type` は別々に確認する

## Edge Cases

- ユーザーが GitHub URL ではなくローカルパスを指定した場合 → そのパスの `config/params.yml` を直接編集する
- 既存の params.yml に追記したい場合 → 既存のブランド設定を保持しつつ新規ブランドを追加。旧キー（移行表参照）は移行先へ置き換える
- `tdx describe` が権限エラーで失敗した場合 → ユーザーにカラム名を手動で入力してもらう
- 同じブランドを複数プラットフォームに送信したい場合 → brand_name を `{brand}_{platform}` の形式で区別する
- **Yahoo / LINE で `channel_id` が空なのに `line_uid` を送る設定にしている場合**: 送信データから `line_uid` は外れる。LINE で `line_uid` を使うなら `channel_id` を必ず設定する
- **OpenAI の `web` に URL がない場合**: `col_url` / `pcol_url` を設定する。日次データに URL がないなら `openai_daily_action_source` は `offline` にする
- **X (Twitter) はコネクタ非対応**: `py_scripts/push_x.py` が `capi_send` テーブルを直接クエリし、X Ads API へ送信する。デプロイ前に `requirements.txt` がプロジェクトルートに存在することを確認する
- **X の event_id と conversion_id の違いに注意**: `x_event_id` はEvents Managerで作成した固定のイベントID（全送信で共通の1つの値）。注文ごとに変わる値は `conversion_id`（TD側の `event_id`/注文IDをそのまま使用）であり、重複排除に使われる。ここを混同するとX側で正しく計測されない


