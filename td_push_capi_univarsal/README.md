# CAPI 汎用送信ワークフロー

購買コンバージョンデータを各種広告プラットフォームの Conversion API (CAPI) へ送信する、パラメータ駆動型の汎用ワークフローです。

- ローカルのフォルダ名: `td_push_capi_univarsal`
- TD 上のワークフロープロジェクト名: `tdx.json` の `workflow_project`（`common_push_capi`）。フォルダ名を変えても TD 上の名前は変わりません。

## 対応プラットフォーム

| プラットフォーム | platform 値 | コネクタ種別 | 主な用途 |
|---|---|---|---|
| Meta (Facebook) | `facebook` | Facebook CAPI | Facebook / Instagram 広告 CAPI |
| Yahoo 広告 | `yahoo` | `yahoo_conversion_v2` | Yahoo 広告 Conversion Export v2 |
| LINE 広告 | `line` | `yahoo_conversion_v2` | LINE 広告 コンバージョン。Yahoo と同じコネクタ種別を使い、設定はブランドごとに分ける |
| TikTok | `tiktok` | TikTok Events API | TikTok Events API |
| Google Store Sales | `google_store_sales` | Google Enhanced Conversions (店舗売上) | 店舗売上の送信 |
| Google Enhanced Web | `google_enhanced_web` | Google Enhanced Conversions (ウェブ) | Web のコンバージョン送信 |
| Google Data Manager for Conversions | `google_data_manager_for_conversions` | Google Data Manager for Conversions | Google Ads への Offline / Online / Store Sales コンバージョン送信 |
| Pinterest | `pinterest` | Pinterest CAPI | Pinterest CAPI |
| Snapchat | `snapchat` | Snapchat CAPI | Snapchat CAPI |
| X (Twitter) | `x` | なし（`py>` で直接送信） | X Ads Conversion API（コネクタ非対応） |
| OpenAI | `openai` | OpenAI Conversion API Export | OpenAI 広告 コンバージョン（テンプレートは `order_created` のみ対応） |

## Treasure Studio で対話的にセットアップ

Treasure Studio (または Claude Code) でこのリポジトリの README.md を読み込むと、対話形式で `config/params.yml` を生成できます。

### 使い方

Treasure Studio のチャットで以下のように伝えてください:

> 「このリポジトリのCAPIワークフローを設定したい: https://github.com/{org}/{repo}」

README.md が読み込まれると、AI が対話形式でヒアリングを開始し、以下を順番に質問します:

1. 送信先プラットフォーム (Facebook / Yahoo / LINE / TikTok / Google / Google Data Manager for Conversions / Pinterest / Snapchat / X / OpenAI)
2. ブランド名・コネクタ名
3. JS-SDK の有無・データソース（共通設定）
4. メアドの取得方法・会員マスタ
5. カラム名マッピング（識別子を含む）
6. フィルタ条件
7. プラットフォーム固有設定（Yahoo / LINE / OpenAI を含む）

生成された `config/params.yml` のデプロイは、下記「デプロイ手順」（dry-run 確認 → 承認 → 実行）に従ってください。

### スキルとしてインストール（オプション）

より確実にトリガーさせたい場合は、同梱の `SKILL.md` をローカルにインストールできます:

```bash
mkdir -p ~/.cache/tdx/.claude/skills/capi-config-setup
cp SKILL.md ~/.cache/tdx/.claude/skills/capi-config-setup/SKILL.md
```

## ファイル構成

```
td_push_capi_univarsal/
├── README.md                                  # 本ファイル
├── SKILL.md                                   # Treasure Studio 対話設定スキル
├── TIPS.md                                    # 実装上の注意点
├── hourly_push_capi.dig                       # 毎時送信 (JS-SDKデータ)
├── daily_push_capi.dig                        # 日次補完送信 (購買データ)
├── tdx.json                                   # tdx CLI 設定 (workflow_project: common_push_capi)
├── config/
│   └── params.yml                             # 全パラメータ設定 (★ 編集対象)
├── query/
│   ├── create_hourly_base.sql                 # 毎時: ベースデータ作成 (メアドあり)
│   ├── create_hourly_base_join_email.sql      # 毎時: ベースデータ作成 (メアドなし→会員マスタJOIN)
│   ├── create_empty_hourly_base.sql           # js_enabled=false時の空ベース
│   ├── create_daily_base.sql                  # 日次: ベースデータ作成 (メアドあり)
│   ├── create_daily_base_join_email.sql       # 日次: ベースデータ作成 (メアドなし→会員マスタJOIN)
│   ├── check_push_log_exists.sql              # 送信ログテーブルの存在確認
│   ├── stage_brand.sql                        # ブランド・媒体ごとの未送信行の抽出（brand_name + platform で判定）
│   ├── stage_brand_initial.sql                # 初回用（送信ログテーブルなし）
│   ├── insert_push_log.sql                    # 従来媒体（メアドで送信するもの）の送信ログ記録（送信対象と同じ条件）
│   ├── insert_google_data_manager_push_log.sql # Google Data Manager送信対象ログ記録
│   ├── prepare_yahoo_v2.sql                   # Yahoo / LINE: 送信対象行の抽出・ly_*/電話番号の整形 (capi_yahoo_v2_send)
│   ├── prepare_openai.sql                     # OpenAI: 送信対象行の抽出 (capi_openai_send)
│   ├── insert_yahoo_v2_push_log.sql           # Yahoo / LINE: 実際の送信対象のみ送信ログ記録（test_flag=true は記録しない）
│   ├── insert_openai_push_log.sql             # OpenAI: 実際の送信対象のみ送信ログ記録
│   ├── push_facebook.sql                      # Facebook CAPI フォーマット
│   ├── push_yahoo.sql                         # Yahoo / LINE 共通: yahoo_conversion_v2 フォーマット
│   ├── push_openai.sql                        # OpenAI: Conversion API フォーマット
│   ├── push_tiktok.sql                        # TikTok フォーマット
│   ├── push_google_store_sales.sql            # Google Store Sales フォーマット
│   ├── push_google_enhanced_web.sql           # Google Enhanced Web フォーマット
│   ├── push_google_data_manager_for_conversions.sql # Google Data Manager for Conversions フォーマット
│   ├── push_pinterest.sql                     # Pinterest フォーマット
│   ├── push_snapchat.sql                      # Snapchat フォーマット
│   └── push_x.sql                             # X (Twitter) 送信対象抽出
├── py_scripts/
│   ├── __init__.py
│   └── push_x.py                              # X Conversion API 送信（py> で直接API送信）
└── requirements.txt                           # py> タスク用の依存パッケージ
```

## 動作概要

### 毎時送信 (`hourly_push_capi.dig`)

JS-SDK で取得したページビュー/購買データを **1時間ごと** に送信します。

```
毎時実行 → JS-SDKデータ抽出 → 共通ベース作成 → 送信対象の抽出 → 送信 → 送信ログ記録
```

- 対象: `common.js_enabled: true` の場合のみ。`false` の場合は空のベースになり、送信は行われません
- 時間窓: スケジュール時刻の **2時間前〜1時間前** (データ遅延を考慮)
- オーダーID をキーに重複排除・送信済み判定

### 日次補完送信 (`daily_push_capi.dig`)

購買テーブルから **毎日10:00 JST** に未送信分を補完送信します。

```
毎日10:00 → 購買データ抽出 → 共通ベース作成 → 送信対象の抽出 → 送信 → 送信ログ記録
```

- 対象: **全ブランド** (`js_enabled` の値に関係なく)
- `js_enabled: true` → 毎時で送れなかった分の補完
- `js_enabled: false` → このWFが唯一の送信手段
- 時間窓: 前日1日分 (`TD_INTERVAL -1d`)

### 送信対象の抽出と送信済み管理

- ブランドごとに、送信ログ（`capi_push_log`）に無い行を `capi_send` に抽出してから送信します。新形式のログは `brand_name` + `platform` + `event_id` で判定します。`platform` がない旧ログは同一ブランドの全媒体に適用されるため、旧ブランド名を別媒体へ流用しないでください（移行手順参照）
- facebook / tiktok / google_store_sales / google_enhanced_web / pinterest / snapchat / x は、送信SQLと同じ条件（メアドあり）を通過した行だけをログに記録します。SQLで除外した行は記録せず、次回の抽出対象に残します。Google Data Managerは専用の適格条件を送信・ログSQLの両方へ適用します
- このログはエクスポートタスク成功後の入力行集合の記録であり、媒体側の行別受領確認ではありません。コネクタによるスキップ、非同期処理、送信成功後のログ失敗などの制約は残ります（TIPS 18）
- Yahoo / LINE (`yahoo_conversion_v2`) と OpenAI は、それぞれ専用の送信対象テーブル `capi_yahoo_v2_send` / `capi_openai_send` に **送信対象として抽出された行だけ** を格納し、送信とログ記録はこのテーブルの行だけを対象にします
- `test_flag: true` の Yahoo / LINE ブランドは、テスト送信として `capi_push_log` に記録しません（テスト送信を本番の送信済み判定に混ぜないため）
- hourly / daily 間の二重送信は、同じ `brand_name` + `platform` の送信ログで防ぎます（TIPS 18 参照）

## 設定方法

### 事前準備

1. **Treasure Data コネクタの作成** (Integration Hub):
   - Yahoo 広告 / LINE 広告: **Yahoo Ads Conversion Export v2** コネクタ（コネクタ種別 `yahoo_conversion_v2`）。Yahoo と LINE で同じ種別を使います
   - OpenAI 広告: **OpenAI Conversion API Export** コネクタ
   - その他の媒体: 各プラットフォームの Result Export コネクタ（X は不要、下記参照）
   - 認証情報（Yahoo の `tag_access_token`、OpenAI の Conversions API Key など）は **コネクタにのみ保存** し、`config/params.yml` には書きません
2. **出力先データベースの作成**: `config/params.yml` の `common.database` で指定するDB
3. **送信ログテーブルの作成**: `capi_push_log` を出力先DBに作成する（列の並びは「送信ログテーブルの移行」を参照）。既存テーブルがある場合は `platform` 列の追加が必要です
4. **X (Twitter) を使う場合のみ**: `requirements.txt` がプロジェクトルートに配置されていることを確認（`py>` タスクが実行時に自動インストールする）

### config/params.yml の編集

`config/params.yml` がこのワークフローの **唯一の編集対象** です。

#### 構造

```yaml
common:            # 全ブランド共通: データソース・カラム・フィルタ
  database: td_capi_universal
  currency: JPY
  ...

brand:             # 送信先ごとの設定（1 ブランド = 1 送信先）
  - brand_name: brand_yahoo
    platform: yahoo
    connector: brand_yahoo_conv_v2
    ...
```

- `common` の項目は全ブランドで共通です。ブランドごとの差は `brand` の項目だけで表現します
- 存在しないカラムは `""`（空文字）にします。空文字のカラムは SQL 側で `NULL` として扱われます
- 同じブランドを複数プラットフォームに送る場合は、ブランド名を変えて別エントリにします（例: `brand_yahoo` と `brand_line`）

#### 共通設定 (`common`)

| パラメータ | 必須 | 説明 | 例 |
|---|---|---|---|
| `database` | Yes | 中間テーブル・ログの出力先DB | `td_capi_universal` |
| `currency` | Yes | 通貨コード (JPY / USD 等) | `JPY` |
| `timezone` | Yes | タイムゾーン | `Asia/Tokyo` |

#### データソース設定

| パラメータ | 必須 | 説明 | 例 |
|---|---|---|---|
| `js_enabled` | Yes | JS-SDK のデータがあるか (`true` / `false`) | `true` |
| `log_db` | js_enabled=true | JS-SDKログのDB名 | `accesslogs` |
| `log_tbl` | js_enabled=true | JS-SDKログのテーブル名 | `td_pageviews` |
| `purchase_db` | 日次送信を使う場合 | 購買データのDB名 | `brand_a_db` |
| `purchase_tbl` | 日次送信を使う場合 | 購買データのテーブル名 | `purchases` |

#### メアド・会員マスタ設定

| パラメータ | 必須 | 説明 | 例 |
|---|---|---|---|
| `js_has_email` | Yes | JS-SDKのデータにメアドがあるか (`true` / `false`) | `true` |
| `purchase_has_email` | Yes | 購買データにメアドがあるか (`true` / `false`) | `false` |
| `email_hashed` | Yes | メアドが事前ハッシュ済みか（X 用） | `false` |
| `phone_hashed` | Yes | 電話番号が事前ハッシュ済みか（X 用） | `false` |
| `member_db` | 会員マスタを使う場合 | 会員マスタDB | `brand_b_master` |
| `member_tbl` | 会員マスタを使う場合 | 会員マスタテーブル | `members` |
| `member_id_col` | 会員マスタを使う場合 | 会員マスタの会員IDカラム | `member_id` |
| `member_email_col` | 会員マスタを使う場合 | 会員マスタのメアドカラム | `email` |
| `member_phone_col` | 任意 | 会員マスタの電話番号カラム | `phone` |

> **会員マスタ JOIN の条件**: `member_db` / `member_tbl` / `member_id_col` / `member_email_col` の4つがすべて設定されている場合のみ、会員IDで会員マスタを LEFT JOIN してメアドを補完します。1つでも空の場合は JOIN せず、メアドは `NULL` になります。JOIN しない場合でも、レコードは保持されます（送信できるかは識別子の有無で決まります）。

#### JS-SDK カラム名 (毎時送信用 `common`)

カラムが存在しない場合は `""`（空文字）を設定します。

| パラメータ | 説明 | 例 | 必須 |
|---|---|---|---|
| `col_order_id` | オーダーID | `transactionid` | Yes |
| `col_email` | メアド | `hashedmailaddress` | js_has_email=true の場合 |
| `col_amount` | 売上金額 | `amount` | Yes |
| `col_member_id` | 会員ID | `userid` | 任意 |
| `col_phone` | 電話番号 | `hashed_user_global_phone_number` | 任意 |
| `col_country` | 国コード | `hashed_user_country` | 任意 |
| `col_user_agent` | ユーザーエージェント | `td_user_agent` | 任意 |
| `col_ip` | IPアドレス | `td_ip` | 任意 |
| `col_url` | ページURL | `td_url` | 任意（OpenAI の web では必須） |
| `col_referrer_url` | リファラURL | `td_referrer` | 任意 |
| `col_fbc` | Facebook Click ID | `fbc` | Facebook 以外は `""` |
| `col_fbp` | Facebook Pixel ID | `fbp` | Facebook 以外は `""` |
| `col_ly_su` | Yahoo ユーザー識別子（`_ly_su` Cookie） | `ly_su` | 任意（Yahoo / LINE の識別子） |
| `col_ly_c` | Yahoo クリック識別子（`_ly_c`） | `ly_c` | 任意（Yahoo / LINE の識別子） |
| `col_ly_r` | Yahoo 追跡識別子（`_ly_r` Cookie） | `ly_r` | 任意（Yahoo / LINE の識別子） |
| `col_line_uid` | LINE ユーザーID | `line_uid` | 任意（LINE の識別子。送る場合は `channel_id` が必要） |
| `col_ifa` | 広告ID（IDFA / AAID） | `ifa` | 任意（Yahoo のみ。OpenAI へは送らない） |
| `col_obref` | OpenAI の obref 値 | `obref` | 任意（OpenAI・毎時のみ。測定同意がある場合のみ送信） |
| `col_oppref` | OpenAI の oppref 値 | `oppref` | 任意（OpenAI・毎時のみ） |

#### 購買データ カラム名 (日次送信用 `common`)

| パラメータ | 説明 | 例 | 必須 |
|---|---|---|---|
| `pcol_order_id` | オーダーID | `order_id` | Yes |
| `pcol_email` | メアド | `email` | 任意（識別子がない日次データを送るなら設定） |
| `pcol_amount` | 売上金額 | `amount` | Yes |
| `pcol_member_id` | 会員ID | `member_id` | 任意 |
| `pcol_time` | TDのUnix秒タイムスタンプカラム | `time` | Yes |
| `pcol_phone` | 電話番号 | `phone` | 任意 |
| `pcol_url` | 購入ページURL（OpenAI の web では必須） | `page_url` | 任意 |
| `pcol_referrer_url` | リファラURL | `referrer` | 任意 |
| `pcol_ifa` | 広告ID（Yahoo のみ） | `ifa` | 任意 |
| `pcol_ly_su` | Yahoo ユーザー識別子 | `ly_su` | 任意（メアドなしの日次送信用） |
| `pcol_ly_c` | Yahoo クリック識別子 | `ly_c` | 任意（メアドなしの日次送信用） |
| `pcol_ly_r` | Yahoo 追跡識別子 | `ly_r` | 任意（メアドなしの日次送信用） |
| `pcol_line_uid` | LINE ユーザーID | `line_uid` | 任意（送る場合は `channel_id` が必要） |

> 日次送信で `pcol_ly_*` または `pcol_line_uid` を設定すると、メアドがなくても識別子だけで Yahoo / LINE へ送信できます。Yahoo / LINE は、少なくとも1つの識別子が入っている行だけを送信します。

#### フィルタ条件

| パラメータ | 説明 | 例 |
|---|---|---|
| `cnv_conditions` | JS-SDKデータの抽出条件 (WHERE句に追加) | `"transactionid != '' AND transactionid NOT IN ('undefined')"` |
| `purchase_conditions` | 購買データの抽出条件 (WHERE句に追加) | `"1=1"` (条件なし) |

#### ブランド設定 (`brand`) — 共通項目

| パラメータ | 必須 | 説明 | 例 |
|---|---|---|---|
| `brand_name` | Yes | ブランド識別子（英数字とアンダースコアのみ） | `brand_yahoo` |
| `platform` | Yes | 送信先（下記の許可リストの値のみ。それ以外はワークフローが停止します） | `yahoo` |
| `connector` | Yes | TDのコネクタ名（X は `""`） | `brand_yahoo_conv_v2` |

許可される `platform` 値: `facebook` / `yahoo` / `line` / `tiktok` / `google_store_sales` / `google_enhanced_web` / `google_data_manager_for_conversions` / `pinterest` / `snapchat` / `x` / `openai`

#### Yahoo / LINE 固有設定 (`platform: yahoo` または `line`)

Yahoo と LINE は **同じコネクタ種別 `yahoo_conversion_v2`** を使い、設定はブランドごとに別々に持ちます。

| パラメータ | 必須 | 説明 | 例 |
|---|---|---|---|
| `tag_id` | Yes | 広告タグID（Yahoo 広告 / LINE 広告の各タグID） | `"12345678"` |
| `channel_id` | line_uid を送る場合 Yes | LINE のチャネルID。`line_uid` を送らない場合は `""` | `"1234567890"` |
| `event_type` | Yes | イベント種別。既定は `purchase`。下記の許容値のみ | `purchase` |
| `event_snippet_id` | 任意 | イベントスニペットID（Yahoo 側の設定。不要なら `""`） | `""` |
| `test_flag` | Yes | テスト送信フラグ。本番は `false`。`true` の送信は `capi_push_log` に記録されない | `false` |
| `custom_label` | 任意 | カスタムラベル（不要なら `""`） | `""` |
| `skip_invalid_records` | Yes | 不正レコードを読み飛ばすか。`false` 推奨（理由は TIPS 参照） | `false` |
| `stop_on_batch_failure` | Yes | バッチ失敗時に後続バッチを止めるか。`true` 推奨 | `true` |

Yahoo が受け付ける `event_type`: `page_view` / `view_listing` / `view_product` / `view_cart` / `add_cart` / `search` / `check_out` / `purchase` / `generate_lead` / `login` / `reservation` / `sign_up` / `payment_info` / `add_wishlist`。購買データは `purchase` を使います。

ワークフローは `tag_id` が空でないこと、`event_type` が上記の値であることを検証し、違反する場合は送信前に停止します。

#### OpenAI 固有設定 (`platform: openai`)

| パラメータ | 必須 | 説明 | 例 |
|---|---|---|---|
| `openai_pixel_id` | Yes | OpenAI Ads Pixel ID | `"your_pixel_id"` |
| `openai_action_source` | Yes | 毎時（JS-SDK）データの action_source。既定 `web` | `web` |
| `openai_daily_action_source` | Yes | 日次（購買）データの action_source。実際の発生元に合わせて `offline`（例）または `web` | `offline` |
| `openai_event_type` | Yes | イベント種別。テンプレートが対応するのは `order_created` のみ | `order_created` |
| `openai_amount_multiplier` | Yes | 金額を minor unit（最小通貨単位）に換算する倍率。JPY は `1`、USD は `100`。他通貨は通貨ごとに確認して明示的に設定する（推測で `100` にしない）。0 以下は不可 | `1` |
| `openai_skip_invalid_records` | Yes | 不正レコードを読み飛ばすか。`false` 推奨 | `false` |

- `openai_daily_action_source` が `web` の場合、日次データに `pcol_url`（購入ページURL）の設定が必須です
- `action_source` が `web` の行には、http(s) の URL が必要です（毎時は `col_url`、日次は `pcol_url`）
- 1つの OpenAI ブランドで毎時と日次の両方を送信します。毎時と日次で別ブランドを作る必要はありません

#### 既存媒体の固有設定

該当しないプラットフォームのパラメータは `""` を設定してください。

| パラメータ | 対象 | 説明 | 例 |
|---|---|---|---|
| `google_customer_id` | Google (Store Sales / Enhanced Web) | Google Ads の Customer ID（ハイフンなしの数値文字列） | `"1234567890"` |
| `google_conversion_action_id` | Google (Store Sales / Enhanced Web) | コンバージョンアクションID | `"123456789"` |
| `google_dm_conversion_type` | Google Data Manager | 送信種別 (`OFFLINE` / `ONLINE` / `STORE_SALES`) | `ONLINE` |
| `google_dm_operating_account_id` | Google Data Manager | 送信先Google Ads Customer ID（ハイフン可） | `"123456789"` |
| `google_dm_login_account_id` | Google Data Manager | MCC経由時のManager Account ID。直接アクセス時は `""` | `""` |
| `google_dm_conversion_action_id` | Google Data Manager | Google Ads Conversion Action ID | `"conv-123"` |
| `google_dm_event_source` | Google Data Manager | `OFFLINE`時のイベント種別 (`WEB` / `APP` / `PHONE` / `MESSAGE` / `OTHER`) | `WEB` |
| `google_dm_store_id` | Google Data Manager | `STORE_SALES`時の店舗ID | `"store-001"` |
| `google_dm_ad_user_data_consent` | Google Data Manager | ユーザーデータ利用同意 | `CONSENT_GRANTED` |
| `google_dm_ad_personalization_consent` | Google Data Manager | 広告パーソナライズ同意 | `CONSENT_GRANTED` |
| `google_dm_skip_invalid_records` | Google Data Manager | 不正レコードをスキップするか。送信ログの正確性を優先して `false` 推奨 | `false` |
| `google_dm_waiting_for_request_status` | Google Data Manager | API処理結果をポーリングするか。毎時処理は `false`、最終結果を同期確認する場合のみ `true` | `false` |
| `x_pixel_id` | X | Events Manager で発行される Pixel ID | `"oka17"` |
| `x_event_id` | X | Events Manager で作成した**固定**のイベントID（注文IDではない） | `"ol288"` |
| `x_consumer_key` / `x_consumer_secret` | X | Developer Portal で発行するOAuth1.0a Consumer Key/Secret | - |
| `x_access_token` / `x_access_token_secret` | X | Developer Portal で発行するOAuth1.0a Access Token/Secret | - |

> X の OAuth 値は現行の設計どおり `params.yml` に記載します。このファイルを Git で管理する場合は、公開範囲に注意してください。

#### 旧設定からの移行

以下の旧キーは削除済みです。既存の `params.yml` に残っている場合は、移行先に置き換えてください。

| 旧キー | 移行先 | 備考 |
|---|---|---|
| `yahoo_ydn_conv_io` | `tag_id` | 同じ値とは限りません。Yahoo 広告の管理画面で新しいタグIDを確認してください |
| `yahoo_ydn_conv_label` | 対応する設定なし | `event_snippet_id` と同じ値とは限らないため、移行時に値を確認してください |
| `yahoo_app_id` | 対応なし（削除） | Yahoo / LINE の v2 設定では使いません |
| `line_tag_id` | `tag_id` | LINE のタグIDを移行 |
| `line_access_token` | コネクタの認証情報 | `params.yml` には置きません。Integration Hub のコネクタに設定します。既に Git に記録された値は再発行を検討してください |

### 送信データの仕様

#### 金額 (`value` と `value_decimal`)

- 従来媒体の `value` は整数（BIGINT）のまま変更しません
- Yahoo / LINE と OpenAI 用に、小数を保持する `value_decimal` を別に作ります。Yahoo は `custom_value`、OpenAI は `data_amount`（minor unit）の元になります

#### Yahoo / LINE（`yahoo_conversion_v2`）

- **必須**: `event_type`、`event_time`（Unix 秒・10桁。Yahoo 側の制限により直近 90 日以内）、識別子 1 つ以上（`ly_su` / `ly_c` / `ly_r` / `line_uid` / `hashed_email` / `hashed_phone_number` / `ifa` のいずれか）
- **識別子の扱い**: `line_uid` は `channel_id` が設定されている場合のみ有効です。`channel_id` が空の場合、ワークフローは `line_uid` を送信データから外します
- **`transaction_id`**: 注文IDを使用。最大 64 文字、使用できる文字は英数字と `-_.!~*'();/?:@&=+$,%#` のみ
- **金額**: `custom_value`（`value_decimal` 由来）と `custom_currency`。通貨は JPY または USD のみ
- **メアド・電話番号**: 生値でも SHA-256 のハッシュ値（64桁 hex）でも可。生値はコネクタがハッシュ化します。電話番号は国際形式（例: `+819012345678`）で渡すことを推奨します（TD 側の正規化仕様は未記載のため）。生値はハイフン・スペース等を除去し、数字と先頭の `+` だけを送ります（ハッシュ値はそのまま）
- **`ly_su` / `ly_c` / `ly_r`**: Cookie の値（`_ly_su` / `_ly_c` / `_ly_r`）をそのまま設定します。URL パラメータ由来の `_ly_c` は、Yahoo の仕様どおり先頭にタイムスタンプと `.` が必要です。`<timestamp>.<id>` の形式に合わない値は送信時に空欄扱いになります（その行は他の識別子があれば送信）
- **`ifa`**: IDFA は大文字、AAID は小文字で渡します（Yahoo の仕様）
- ワークフローは、以下に該当する行を送信前に除外します（集計・ログの対象からも外れます）: 識別子がない行、`transaction_id` が 64 文字を超える行、`event_time` が範囲外の行、通貨が JPY / USD 以外の行

#### OpenAI（`openai`）

- **必須**: `event_id`（注文IDなど安定した一意の値。再送時も同じ値を使う）、`event_type`（`order_created`）、`event_timestamp`（ミリ秒。過去 7 日以内・未来は 10 分以内）、`action_source`
- **`action_source = web`**: `source_url` が必須（毎時は `col_url`、日次は `pcol_url`）。http(s) の URL を渡します
- **金額**: `data_amount` は minor unit の整数です（`value_decimal` × `openai_amount_multiplier` を四捨五入（`ROUND`））。`data_currency` は ISO 4217 の 3 文字コード（`common.currency`）
- **識別子**: メアド・電話番号・会員ID（`external_id`）。生値でも 64 桁 hex でも可（コネクタが正規化してハッシュ化）
- **`obref`（`col_obref`）**: 値が空でなく、かつ測定の同意がある場合のみ送信します。同意状況をワークフロー側で推測して既定値にしないでください
- **`oppref`（`col_oppref`）**: 値をそのまま渡します
- IDFA は送りません。GAID（Android の広告ID）はテンプレートでマッピングしていません
- テンプレートが対応するイベント種別は `order_created` のみです（OpenAI が受け付ける他のイベント種別は未対応）

### 検証とデプロイ手順

**原則**: 実際の `tdx wf run` の前に必ず dry-run を行い、送信範囲（対象ブランド・想定件数）を説明して、明示的な承認を得てから実行します。承認なしにスケジュールを有効化しないでください。

#### デプロイと dry-run

既存環境では、先に「送信ログテーブルの移行」の停止・実行完了待ち・スキーマ確認を行い、スケジュールを無効のままデプロイします。

```bash
# 1. プロジェクトフォルダへ移動（フォルダ名: td_push_capi_univarsal）
cd td_push_capi_univarsal

# 2. 変更内容の確認のみ（アップロードしない）
tdx wf push --dry-run

# 3. 承認後にアップロード（--skip-validation は使わない）
tdx wf push

# 4. スケジュールの状態を確認。push 後も無効のままであることを確認する
tdx wf schedule list common_push_capi.hourly_push_capi
tdx wf schedule list common_push_capi.daily_push_capi

# 5. 実行の dry-run（タスクグラフと副作用の警告を表示。送信はしない）
tdx wf run common_push_capi.daily_push_capi --dry-run
tdx wf run common_push_capi.hourly_push_capi --dry-run

# 6. 承認を得た後に実行（--param で動作を切り替えない。切り替えは params.yml で行う）
tdx wf run common_push_capi.daily_push_capi
```

- 送信件数は dry-run では取得できない場合があります。取得できない場合は「件数不明」と明記してから承認を得てください
- `tdx wf push --backfill` は、スケジュール停止中の期間を遡って送信するため、承認なしには使わないでください
- スケジュールを有効化する場合は、`tdx wf schedule list` で確認した ID を指定して `tdx wf schedule enable <id>` を実行します（承認後のみ）
- Treasure Workでは現在のTDアカウント・プロファイルを切り替えたり、コマンドで上書きしないでください

### Google Data Manager for Conversions 固有の注意事項

仕様: [Google Data Manager for Conversions Export Integration](https://docs.treasure.ai/int/google-data-manager-for-conversions-export-integration)

Integration Hub で **Google Data Manager for Conversions** のOAuthコネクタを作成し、
その名前を `connector` に指定します。オーディエンスリスト用の
**Google Data Manager** コネクタとは別のコネクタです。

```yaml
brand:
  - brand_name: my_brand_google_dm
    platform: google_data_manager_for_conversions
    connector: my_google_dm_conversions
    google_dm_conversion_type: ONLINE
    google_dm_operating_account_id: "123456789"
    google_dm_login_account_id: ""          # MCC経由時のみ指定
    google_dm_conversion_action_id: "conv-123"
    google_dm_event_source: WEB              # OFFLINE時のみ使用
    google_dm_store_id: ""                  # STORE_SALES時は必須
    google_dm_ad_user_data_consent: CONSENT_GRANTED
    google_dm_ad_personalization_consent: CONSENT_GRANTED
    google_dm_skip_invalid_records: false
    google_dm_waiting_for_request_status: false
```

| conversion_type | 必須データ |
|---|---|
| `OFFLINE` | `event_timestamp`、`event_source`、Google Click ID / email / IPのいずれか。加えて本WFでは送信ログ用の`event_id`が必要 |
| `ONLINE` | `event_timestamp`、`transaction_id`、Google Click ID / email / IPのいずれか |
| `STORE_SALES` | `event_timestamp`、`transaction_id`、金額、通貨、`store_id`、email |

`push_google_data_manager_for_conversions.sql` は共通ベースを次のように変換します。

- `event_time`（TDのUnix秒）→ `event_timestamp`（epoch milliseconds）
- `event_id` → `transaction_id`
- `value` / `currency` → `conversion_value` / `currency`
- `event_source_url` → URLパラメータの `gclid` / `gbraid` / `wbraid` / `dclid`
- `em` / `client_ip_address` → `email` / `ip_address`
- `client_user_agent` → `device_user_agent`

メールアドレスは、未ハッシュならコネクタが正規化してSHA-256ハッシュ化し、
64文字の16進ハッシュ値ならそのまま利用します。現在の共通ベースが送信する識別子は
URL内のGoogle Click ID、email、IPです。phone / address / mobile device ID等を
使う場合は、共通ベースへのカラム追加が必要です。

`STORE_SALES` は日次WFのみから送信され、Google側のallowlist登録も必要です。
送信対象外レコードを誤って送信済みにしないよう、専用ログSQLで送信クエリと
同じ適格条件を適用します。`skip_invalid_records: false` を推奨します。
`waiting_for_request_status: false` では送信ログはリクエスト受付成功を表し、
最終処理結果まで同期確認する場合のみ `true` にします。

### X (Twitter) 固有の注意事項

X にはTDのResult Exportコネクタが存在しないため、`py>` オペレーターで `py_scripts/push_x.py` を実行し、X Ads API (`POST /12/measurement/conversions/:pixel_id`) へ直接送信します。

- **認証**: OAuth 1.0a（`x_consumer_key` / `x_consumer_secret` / `x_access_token` / `x_access_token_secret` の4点）
- **識別子**: メール・電話番号は SHA256 でハッシュ化（ソルトなし）。電話番号は E.164 形式（`+`付き）に正規化してからハッシュ化する。少なくとも1つの識別子（メール or 電話）が必須
- **`event_id` と `conversion_id` の違い**: `x_event_id` は Events Manager で作成した固定のイベントID（全リクエスト共通の1値）。TD側のオーダーID（他PFの `event_id` 相当）は `conversion_id` として送信し、Pixel との重複排除に使われる
- **`email_hashed` / `phone_hashed`**: `common` 設定が既にハッシュ済みの値なら `true` を設定し、二重ハッシュを避ける
- **レート制限**: 60,000イベント/アカウント/15分

## 設定例

`common` の内容はブランドに共通です。以下の例では、各パターンで変わる項目だけを示します。

### パターン1: JS-SDK + メアドあり (Facebook)

最も一般的なケース。JS-SDKでメアドも取得できる。

```yaml
common:
  js_enabled: true
  log_db: brand_a_db
  log_tbl: pageviews
  purchase_db: brand_a_db
  purchase_tbl: purchases
  js_has_email: true
  purchase_has_email: true
  member_db: ""
  member_tbl: ""
  member_id_col: ""
  member_email_col: ""
  col_order_id: transactionid
  col_email: hashedmailaddress
  col_amount: amount
  col_member_id: userid
  col_phone: hashed_user_global_phone_number
  col_country: hashed_user_country
  col_user_agent: td_user_agent
  col_ip: td_ip
  col_url: td_path
  col_fbc: fbc
  col_fbp: fbp
  pcol_order_id: order_id
  pcol_email: email
  pcol_amount: amount
  pcol_member_id: member_id
  pcol_time: time
  cnv_conditions: "transactionid != '' AND transactionid NOT IN ('undefined')"
  purchase_conditions: "1=1"

brand:
  - brand_name: brand_fb
    platform: facebook
    connector: brand_a_fb_capi
```

### パターン2: JS-SDK + メアドなし → Yahoo と LINE を別ブランドで送信

JSでメアドが取得できないため、会員マスタからJOIN。Yahoo と LINE は同じ注文データを、それぞれ別の設定で送信します。

```yaml
common:
  js_enabled: true
  log_db: brand_b_db
  log_tbl: pageviews
  purchase_db: brand_b_db
  purchase_tbl: purchases
  js_has_email: false
  purchase_has_email: false
  member_db: brand_b_master
  member_tbl: members
  member_id_col: member_id
  member_email_col: email
  col_order_id: transactionid
  col_amount: amount
  col_member_id: userid
  col_user_agent: td_user_agent
  col_ip: td_ip
  col_url: td_path
  col_ly_su: ly_su
  col_ly_c: ly_c
  col_ly_r: ly_r
  col_line_uid: line_uid
  pcol_order_id: order_id
  pcol_amount: amount
  pcol_member_id: member_id
  pcol_time: time
  pcol_ly_su: ly_su
  pcol_ly_c: ly_c
  pcol_ly_r: ly_r
  pcol_line_uid: line_uid
  cnv_conditions: "transactionid != ''"
  purchase_conditions: "1=1"

brand:
  - brand_name: brand_yahoo
    platform: yahoo
    connector: brand_yahoo_conv_v2
    tag_id: "12345678"
    channel_id: ""
    event_type: purchase
    event_snippet_id: ""
    test_flag: false
    custom_label: ""
    skip_invalid_records: false
    stop_on_batch_failure: true

  - brand_name: brand_line
    platform: line
    connector: brand_line_conv_v2
    tag_id: "87654321"
    channel_id: "1234567890"          # line_uid を送るため必須
    event_type: purchase
    event_snippet_id: ""
    test_flag: false
    custom_label: ""
    skip_invalid_records: false
    stop_on_batch_failure: true
```

### パターン3: JS-SDKなし・購買データのみ (Google Store Sales)

JSは使わず、日次の購買データのみで運用。

```yaml
common:
  js_enabled: false
  log_db: ""
  log_tbl: ""
  purchase_db: brand_c_db
  purchase_tbl: purchases
  js_has_email: false
  purchase_has_email: true
  member_db: ""
  member_tbl: ""
  member_id_col: ""
  member_email_col: ""
  pcol_order_id: order_id
  pcol_email: email
  pcol_amount: amount
  pcol_member_id: member_id
  pcol_time: time
  cnv_conditions: "1=1"
  purchase_conditions: "1=1"

brand:
  - brand_name: brand_c_google_ss
    platform: google_store_sales
    connector: brand_c_google_ss
    google_customer_id: "1234567890"
    google_conversion_action_id: "123456789"
```

### パターン4: 購買データのみ・メアドなし (Yahoo / 識別子のみ)

日次の購買データにメアドがなく、Yahoo の識別子（`ly_*`）で送信する場合。会員マスタを設定しなければ JOIN は行われず、メアドは `NULL` になります。

```yaml
common:
  js_enabled: false
  purchase_db: brand_d_db
  purchase_tbl: purchases
  js_has_email: false
  purchase_has_email: false
  pcol_order_id: order_id
  pcol_amount: amount
  pcol_member_id: member_id
  pcol_time: time
  pcol_ly_su: ly_su
  pcol_ly_c: ly_c
  pcol_ly_r: ly_r
  cnv_conditions: "1=1"
  purchase_conditions: "1=1"

brand:
  - brand_name: brand_d_yahoo
    platform: yahoo
    connector: brand_d_yahoo_conv_v2
    tag_id: "12345678"
    channel_id: ""
    event_type: purchase
    event_snippet_id: ""
    test_flag: false
    custom_label: ""
    skip_invalid_records: false
    stop_on_batch_failure: true
```

### パターン5: JS-SDK + OpenAI

毎時の JS-SDK データは `web`、日次の購買データは `offline` として送信する例。

```yaml
brand:
  - brand_name: brand_openai
    platform: openai
    connector: brand_openai_conv
    openai_pixel_id: "your_pixel_id"
    openai_action_source: web
    openai_daily_action_source: offline
    openai_event_type: order_created
    openai_amount_multiplier: 1          # JPY の例（USD なら 100）
    openai_skip_invalid_records: false
```

## 処理フロー詳細

```
1. 共通ベース作成 (create_*_base*.sql → capi_base)
   ├─ 毎時: js_enabled=false → 空ベース
   ├─ メアド: js_has_email / purchase_has_email で分岐
   └─ 会員マスタ JOIN: member_db / member_tbl / member_id_col / member_email_col がすべて設定されている場合のみ
2. ブランドごとに `stage_brand.sql` → `capi_send`（未送信の行）
   従来媒体 (facebook / tiktok / google_* / pinterest / snapchat / x)
   push_{platform}.sql → insert_push_log.sql（メアドのある行のみ記録）
3. Yahoo / LINE (yahoo_conversion_v2)
   prepare_yahoo_v2.sql → capi_yahoo_v2_send → push_yahoo.sql → 同じ行を capi_push_log に記録
   （test_flag: true の場合は記録しない）
4. OpenAI
   prepare_openai.sql → capi_openai_send → push_openai.sql → 同じ行を capi_push_log に記録
5. 送信件数チェック（0件ならスキップ）
```

## 中間テーブル

ワークフロー実行時に以下のテーブルが作成されます:

| テーブル名 | 用途 | 永続 |
|---|---|---|
| `capi_base` | 共通ベースデータ (create_table で毎回上書き) | No |
| `capi_send` | ブランドごとの未送信データ（ブランドの処理ごとに上書き） | No |
| `capi_yahoo_v2_send` | Yahoo / LINE の送信対象データ (毎回上書き) | No |
| `capi_openai_send` | OpenAI の送信対象データ (毎回上書き) | No |
| `capi_push_log` | 送信ログ (insert_into で追記。`brand_name` + `platform` + `event_id` で送信済みを判定) | **Yes** |

## 送信ログテーブルの移行（platform 列の追加）

送信ログは `brand_name` と `platform`（媒体）の組で送信済みを判定します。既存の `capi_push_log` がある場合は、次の順序で移行してください。各リモート変更は事前承認が必要です。

1. hourly / daily両方のスケジュールを停止する（無効化しても実行中のattemptは止まりません）
2. 両WFの実行中attemptがすべて完了したことを確認し、移行中は手動実行・retryもしない
3. `platform` 列を追加し、スキーマを確認する（既存データは消えません）
4. スケジュールを無効のまま新版WFをデプロイし、両方が無効であることを再確認する
5. dry-runと承認済みの少量送信で検証する
6. 別途明示承認を得てスケジュールを再開する（hourly / dailyの同時実行を避ける）

旧版のログ書き込みが走ったまま列を追加しないでください。旧版・新版で出力列数が異なり、外部送信後のログ失敗や再送につながる可能性があります。

```sql
ALTER TABLE <出力先DB>.capi_push_log ADD COLUMN platform varchar
```

- 追加前の行は `platform IS NULL` です。再送防止のため、同じ `brand_name` を持つすべての媒体に適用します。旧ブランド名を別媒体へ流用せず新しい名前を付けるか、旧設定から実際の送信先を確認して履歴を補完してから利用してください。NULL履歴から実際の媒体を自動推定しません
- DDL は実行前に確認してください。実行後は `tdx describe <出力先DB>.capi_push_log` で `platform` 列が末尾にあることを確認します
- 既存ログに `platform` 列がないまま新版を実行すると、送信前の `stage_brand.sql` で列参照エラーになります。事前にスキーマを確認してください
- 新規に作る場合は、次の順で列を作成してください: `event_name, event_time, em, ph, fn, ln, country, value, currency, event_source_url, action_source, client_user_agent, client_ip_address, event_id, push_time, brand_name, source_type, platform`

### 任意: 移行前に記録された「送信していない行」の整理

移行前の従来媒体は、メアドのない行も送信済みとして記録されています。その注文は以後も従来媒体の対象外になります。メアドが後から補完される注文だけが影響を受けるため、通常は整理しなくてかまいません。整理する場合は、先に対象を確認してください（削除は取り消せません）。

```sql
-- 対象の確認（従来媒体のブランド名に置き換える）
SELECT brand_name, COUNT(*) AS cnt
FROM <出力先DB>.capi_push_log
WHERE platform IS NULL
  AND brand_name IN ('brand_meta', 'brand_tiktok')
  AND (em IS NULL OR em = '')
GROUP BY brand_name
```

DELETE の可否は環境によって異なるため、実行前に権限と方法を確認してください。

## ローカル回帰テスト

```bash
python3 -I -m unittest discover -s tests -v
```

標準ライブラリのみを使用します。SQLiteで実際のstage/log SQLを実行し、SQL除外行の未記録、メールの後日補完、ブランド・媒体分離、部分的な既存ログ、失敗後の先頭再実行、旧ログを検証します。TDのTrino/Digdagおよび広告コネクタの実機テストではありません。

## トラブルシューティング

| 症状 | 原因 | 対処 |
|---|---|---|
| 送信件数が常に0 | 送信済み判定が効きすぎている（同じ `brand_name` + `platform` で記録済み） | `capi_push_log` の `brand_name` と `platform` を確認 |
| メアドが全て NULL | 会員マスタの JOIN 設定が不完全（4項目のどれかが空） | `member_db` / `member_tbl` / `member_id_col` / `member_email_col` を確認。メアドが不要な識別子設計なら問題なし |
| 二重送信が発生 | `capi_push_log` テーブルが存在しない | 出力先DBに空テーブルを作成 |
| コネクタエラー | TDコネクタ名の設定間違い、または認証切れ | `connector` の値とTDコンソールのコネクタ名を照合。認証情報はコネクタ側で確認 |
| hourly で何も処理されない | `common.js_enabled` が `false` | `params.yml` の設定を確認 |
| 金額が0や NULL | `col_amount` / `pcol_amount` のカラム名が間違い | 実テーブルのカラム名を確認 |
| 実行時に停止し `platform` のエラーが出る | 許可リスト外の `platform` 値 | 許可される値（対応プラットフォーム参照）に修正 |
| Yahoo / LINE で識別子不足のエラー | 識別子（`ly_*` / `line_uid` / `hashed_*` / `ifa`）が1つもない行 | 列マッピング（`col_ly_*` / `pcol_ly_*` 等）を確認 |
| LINE で `line_uid` が送られない | `channel_id` が空 | `channel_id` を設定する（空の場合は `line_uid` は送信データから外れる） |
| Yahoo で行が送られない（期間外） | `event_time` が 90 日より前 | 購買データの `pcol_time` と処理時点を確認 |
| Yahoo で `transaction_id` が拒否される | 64 文字超、または使用できない文字を含む | 注文IDの形式を確認 |
| OpenAI で `source_url` のエラー | `action_source` が `web` で URL 列が空、または http(s) でない | `col_url` / `pcol_url` を確認。日次を `offline` にするなら `openai_daily_action_source` を見直す |
| OpenAI の金額が桁違い | `openai_amount_multiplier` と `common.currency` の組み合わせが不一致 | 通貨ごとの倍率（JPY: 1、USD: 100 等）を確認 |
| OpenAI で `event_timestamp` の範囲エラー | 7 日より前、または未来 10 分超のデータ | 時間窓とデータの日時を確認 |
| 送信されず、ログにだけ残る（不正行） | `skip_invalid_records: true` の影響 | `skip_invalid_records` を `false` にする（TIPS 参照） |
| テスト送信の行が本番の送信対象から消えない | `test_flag: true` の送信は `capi_push_log` に記録されない（想定どおり） | 本番に切り替えるときは `test_flag` を `false` にする |
| X への送信が失敗する（401） | OAuth1.0a認証情報の間違い、またはトークンの権限不足（`AD_MANAGER`/`ACCOUNT_ADMIN` 権限が必要） | `x_consumer_key` 等をDeveloper Portalで再確認 |
| X で計測されない | `x_event_id`（固定値）と `conversion_id`（注文ID）を混同している | `x_event_id` は全送信共通の固定値であることを確認 |

## 注意事項

- **SQLエンジン**: Trino を使用しています（Hive ではありません）
- **タイムゾーン**: JST (Asia/Tokyo) 基準で動作します
- **ハッシュ処理**: Yahoo / LINE と OpenAI の識別子（メアド・電話番号など）は、各コネクタが生値をハッシュ化します。64 桁の hex 値もそのまま使えます。従来媒体についても、各 TD コネクタが自動で処理します。SQL 側での事前ハッシュは不要です（X を除く。X の扱いは上記参照）
- **送信ログの肥大化**: `capi_push_log` は追記のみのため、長期運用時は定期的なクリーンアップを検討してください
- **既知の制約**: コネクタが `skip_invalid_records: true` で読み飛ばした行は TD からは判別できず、送信済みとして記録されます（TIPS 16 参照）。移行前に記録された不適格行は残ります（「送信ログテーブルの移行」参照）

---

<!-- AI_SETUP_INSTRUCTIONS_START -->
## AI向け: 対話的セットアップ手順

> **このセクションは Treasure Studio / Claude Code 等の AI アシスタントが読み取り、対話的に `config/params.yml` を生成するための指示です。人間が直接編集する場合は上記の「設定方法」セクションを参照してください。**

### 前提

このREADME.mdを読み込んだ時点で、AIは以下の対話的セットアップを実行できる。スキルのローカルインストールは不要。詳細な質問の進め方は同梱の `SKILL.md` に従う。

### セットアップフロー

#### Step 1: リポジトリ取得

1. GitHub URL からリポジトリをクローン、または `config/params.yml` を取得する
2. 現在の設定内容を把握する（`common` と `brand` の両方）

#### Step 2: 対話的ヒアリング

以下の情報を **段階的に** ユーザーに質問する。選択肢を提示し、1回の質問で3〜4項目までに収める。

**2-1. プラットフォーム選択（複数選択可）**: 対応プラットフォーム表の `platform` 値から選ぶ（Yahoo と LINE は別ブランドにする）。

**2-2. ブランド基本情報（プラットフォームごとに）**: `brand_name`（英数字と_のみ）、`connector`（TDのコネクタ名。yahoo / line は `yahoo_conversion_v2` 種別、openai は OpenAI Conversion API Export 種別。X は `""`）。

**2-3. データソース設定（`common`）**: JS-SDK のデータがあるか（`js_enabled`）。ある場合は `log_db`, `log_tbl`。購買データの `purchase_db`, `purchase_tbl`。

**2-4. テーブルスキーマ確認とカラム自動提案**: DB名・テーブル名が確定したら、ユーザーに許可を得た上で以下を実行する（SELECT のみ）:

```bash
# スキーマ確認
tdx describe {db}.{table}

# サンプルデータ取得（最新10件）
tdx query -d {db} --limit 10 "SELECT * FROM {table} ORDER BY time DESC LIMIT 10"
```

既定プロファイル以外を使う場合は `tdx -p <profile> ...` を各コマンドに付け、`tdx use profile` などで既定を切り替えない。

取得した結果から、以下の項目を **AI が自動推定して提案** する:

| 設定項目 | カラム名のヒント | サンプル値のヒント |
|---|---|---|
| `col_order_id` / `pcol_order_id` | `transaction`, `order`, `receipt`, `tran` を含む | 英数字の一意な値（Yahoo は 64 文字以内） |
| `col_email` / `pcol_email` | `email`, `mail`, `address` を含む | `@`を含む文字列、またはハッシュ値(64文字hex) |
| `col_amount` / `pcol_amount` | `amount`, `price`, `revenue`, `sales`, `value` を含む | 数値（小数がある場合は `value_decimal` 側で保持） |
| `col_member_id` / `pcol_member_id` | `user`, `member`, `customer`, `cid`, `uid` を含む | IDらしい値 |
| `col_phone` / `pcol_phone` | `phone`, `tel` を含む | 電話番号形式またはハッシュ値 |
| `col_country` | `country`, `region`, `geo` を含む | 国コード (JP, US等) |
| `col_user_agent` | `ua`, `user_agent`, `td_user_agent` を含む | ブラウザUA文字列 |
| `col_ip` | `ip`, `td_ip`, `remote_addr` を含む | IPアドレス形式 |
| `col_url` / `pcol_url` | `url`, `path`, `page`, `td_path`, `td_url` を含む | URL文字列（OpenAI の web に必要） |
| `col_referrer_url` / `pcol_referrer_url` | `referrer`, `referer`, `ref` を含む | URL文字列 |
| `col_fbc` | `fbc`, `click_id` を含む | `fb.1.`で始まる文字列 |
| `col_fbp` | `fbp`, `pixel` を含む | `fb.1.`で始まる文字列 |
| `col_ly_su` / `pcol_ly_su` | `ly_su` を含む | `タイムスタンプ.ID` 形式（`_ly_su` Cookie） |
| `col_ly_c` / `pcol_ly_c` | `ly_c` を含む | `_ly_c` Cookie またはURLパラメータ由来（URL由来はタイムスタンプ付与が必要） |
| `col_ly_r` / `pcol_ly_r` | `ly_r` を含む | `タイムスタンプ.乱数` 形式（`_ly_r` Cookie） |
| `col_line_uid` / `pcol_line_uid` | `line_uid`, `lineuid` を含む | LINE のユーザーID |
| `col_ifa` / `pcol_ifa` | `ifa`, `idfa`, `aaid`, `gaid` を含む | 広告ID（Yahoo のみに使う） |
| `col_obref` | `obref` を含む | OpenAI の obref 値（測定同意がある場合のみ） |
| `col_oppref` | `oppref` を含む | OpenAI の oppref 値 |
| `pcol_time` | `time`, `timestamp`, `created`, `date` を含む | TDのUnix秒タイムスタンプ（日時文字列は事前変換） |

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
  col_phone     → (該当なし)      → "" に設定

この提案でよろしいですか？修正があれば指定してください。
```

**重要:**
- 提案はあくまで推定であり、**ユーザーの修正・上書きを常に受け付ける**
- 推定に自信がない場合は複数の候補を提示し、ユーザーに選択してもらう
- 該当カラムが見つからない場合は `""` (NULL出力) を提案する
- 購買テーブル、JS-SDKテーブル、会員マスタテーブルそれぞれに対して実行する

**2-5. メアド・会員マスタ設定**: メアドカラムが見つかった場合は `js_has_email` / `purchase_has_email` を `true` に提案。見つからない場合は `false` を提案し、会員マスタ（`member_db`, `member_tbl`, `member_id_col`, `member_email_col`）を質問する。会員マスタの4項目がすべて揃わない場合は JOIN しない。

**2-6. カラムマッピング確定**: Step 2-4 の提案をユーザーが確認・修正した結果を最終的なカラムマッピングとして確定する。識別子だけで送るデータ（メアドなし）の場合は、`col_ly_*` / `pcol_ly_*` / `col_line_uid` / `pcol_line_uid` を確認する。

**2-7. フィルタ条件**: `cnv_conditions`（例: `"transactionid != '' AND transactionid NOT IN ('undefined')"`）、`purchase_conditions`（通常は `"1=1"`）。

**2-8. プラットフォーム固有設定**:
- **Yahoo / LINE** → `tag_id`、`channel_id`（line_uid を送る場合のみ必須）、`event_type`（既定 `purchase`。Yahoo の許容値のみ）、`event_snippet_id`、`test_flag`（既定 `false`）、`custom_label`、`skip_invalid_records`（既定 `false`）、`stop_on_batch_failure`（既定 `true`）。認証情報は質問せず、コネクタ側で設定すると案内する
- **OpenAI** → `openai_pixel_id`、`openai_action_source`（毎時の既定 `web`）、`openai_daily_action_source`（日次の実際の発生元に合わせて `offline` または `web`。`web` なら `pcol_url` が必要）、`openai_event_type`（`order_created` 固定）、`openai_amount_multiplier`（通貨ごとに確認。JPY は 1、USD は 100。推測しない）、`openai_skip_invalid_records`（既定 `false`）。`obref` は測定同意がある場合のみ
- **Google (Store Sales / Enhanced Web)** → `google_customer_id`, `google_conversion_action_id`
- **Google Data Manager for Conversions** → `google_dm_conversion_type` (`OFFLINE` / `ONLINE` / `STORE_SALES`), `google_dm_operating_account_id`, `google_dm_login_account_id`（MCC経由時のみ）, `google_dm_conversion_action_id`, `google_dm_event_source`（OFFLINE時）, `google_dm_store_id`（STORE_SALES時）, `google_dm_ad_user_data_consent`, `google_dm_ad_personalization_consent`, `google_dm_skip_invalid_records`, `google_dm_waiting_for_request_status`
- **X (Twitter)** → `x_pixel_id`（Events Managerで発行）, `x_event_id`（Events Managerで作成した固定イベントID。注文IDではない点に注意）, `x_consumer_key`, `x_consumer_secret`, `x_access_token`, `x_access_token_secret`（Developer Portal で発行するOAuth1.0a認証情報）
- **その他** → 該当パラメータは `""` を自動設定

**2-9. 共通設定**: `common.database`（`params.yml` の値。例: `td_capi_universal`）、`common.currency`（デフォルト: `JPY`）。`currency` と OpenAI の `openai_amount_multiplier` の組み合わせを必ず確認する。

#### Step 3: params.yml 生成

収集した情報から `config/params.yml` を生成する。

**生成ルール:**
- 存在しないカラムは必ず `""` (空文字) にする
- プラットフォームに関係ないパラメータも `""` で必ず含める（全ブランドが同じキー構造を持つこと）
- コメントで各セクションを説明する
- 設定例のコメントアウトされたブランドは削除し、実際のブランド設定のみ出力する
- 認証情報（Yahoo の `tag_access_token`、OpenAI の Conversions API Key、LINE のアクセストークン）は `params.yml` に書かない

**キー構造:** `common` は上記の共通設定の全キー。`brand` の各エントリは `brand_name`, `platform`, `connector`, `tag_id`, `channel_id`, `event_type`, `event_snippet_id`, `test_flag`, `custom_label`, `skip_invalid_records`, `stop_on_batch_failure`, `openai_pixel_id`, `openai_action_source`, `openai_daily_action_source`, `openai_event_type`, `openai_amount_multiplier`, `openai_skip_invalid_records`, `google_customer_id`, `google_conversion_action_id`, `google_dm_*`（全項目）, `tiktok_event_data_source`, `tiktok_event_source_id`, `x_*`（全項目）を持つ。

#### Step 4: 確認・修正

生成した `params.yml` をユーザーに提示し、修正点がないか確認する。

#### Step 5: デプロイ（承認制）

```bash
cd td_push_capi_univarsal
tdx wf push --dry-run      # 確認のみ
tdx wf push                # 承認後
tdx wf schedule list common_push_capi.daily_push_capi
tdx wf run common_push_capi.daily_push_capi --dry-run   # 送信しない。承認を得てから実行
```

- 送信範囲（対象ブランド・想定件数）を説明し、件数が不明な場合は「件数不明」と明記してから承認を得る
- 承認なしに `tdx wf run` を実行しない。スケジュールを有効化しない
- `--param` で動作を切り替えない（切り替えは `params.yml` で行う）

### ヒアリングのコツ

- **スキーマ確認を積極的に行う**: DB・テーブル名が確定したら必ず `tdx describe` と サンプルクエリを実行して提案の精度を上げる
- **提案は修正前提で提示する**: 「この提案でよろしいですか？修正があれば指定してください」と必ず確認する
- **1回の質問で多くを聞きすぎない**: 3〜4項目ずつグルーピングする
- **デフォルト値を提示する**: ユーザーが迷わないように典型的な値を示す
- **選択肢で絞り込む**: 自由入力より選択肢を優先する
- **複数ブランドの場合**: 1ブランド目を詳細に設定し、2ブランド目以降は差分のみ質問する
- **同じブランドを複数プラットフォームに送信する場合**: brand_name を `{brand}_{platform}` の形式で区別する
<!-- AI_SETUP_INSTRUCTIONS_END -->






