# CAPI 汎用送信ワークフロー

購買コンバージョンデータを各種広告プラットフォームの Conversion API (CAPI) へ送信する、パラメータ駆動型の汎用ワークフローです。

## 対応プラットフォーム

| プラットフォーム | platform 値 | 主な用途 |
|---|---|---|
| Meta (Facebook) | `facebook` | Facebook / Instagram 広告 CAPI |
| Yahoo 広告 | `yahoo` | Yahoo ディスプレイ広告 コンバージョン |
| LINE | `line` | LINE 広告 コンバージョン |
| TikTok | `tiktok` | TikTok Events API |
| Google Store Sales | `google_store_sales` | Google Enhanced Conversions (店舗売上) |
| Google Enhanced Web | `google_enhanced_web` | Google Enhanced Conversions (ウェブ) |
| Google Data Manager for Conversions | `google_data_manager_for_conversions` | Google AdsへのOffline / Online / Store Salesコンバージョン送信 |
| Pinterest | `pinterest` | Pinterest CAPI |
| Snapchat | `snapchat` | Snapchat CAPI |
| X (Twitter) | `x` | X Ads Conversion API（コネクタ非対応、`py>` で直接送信） |

## Treasure Studio で対話的にセットアップ

Treasure Studio (または Claude Code) でこのリポジトリの README.md を読み込むだけで、対話形式で `config/params.yml` を自動生成できます。

### 使い方

Treasure Studio のチャットで以下のように伝えてください:

> 「このリポジトリのCAPIワークフローを設定したい: https://github.com/{org}/{repo}」

README.md が読み込まれると、AI が対話形式でヒアリングを開始し、以下を順番に質問します:

1. 送信先プラットフォーム (Facebook / Yahoo / LINE / TikTok / Google / Google Data Manager for Conversions / Pinterest / Snapchat / X)
2. ブランド名・コネクタ名
3. JS-SDK の有無・データソース
4. メアドの取得方法
5. カラム名マッピング
6. フィルタ条件
7. プラットフォーム固有設定

最終的に `config/params.yml` が自動生成され、`tdx wf push` でデプロイできます。

### スキルとしてインストール（オプション）

より確実にトリガーさせたい場合は、同梱の `SKILL.md` をローカルにインストールできます:

```bash
mkdir -p ~/.cache/tdx/.claude/skills/capi-config-setup
cp SKILL.md ~/.cache/tdx/.claude/skills/capi-config-setup/SKILL.md
```

## ファイル構成

```
common_push_capi/
├── README.md                              # 本ファイル
├── SKILL.md                               # Treasure Studio 対話設定スキル
├── hourly_push_capi.dig                   # 毎時送信 (JS-SDKデータ)
├── daily_push_capi.dig                    # 日次補完送信 (購買データ)
├── tdx.json                               # tdx CLI 設定
├── config/
│   └── params.yml                         # 全パラメータ設定 (★ 編集対象)
└── query/
    ├── create_hourly_base.sql             # 毎時: ベースデータ作成 (メアドあり)
    ├── create_hourly_base_join_email.sql  # 毎時: ベースデータ作成 (メアドなし→JOIN)
    ├── create_empty_hourly_base.sql       # js_enabled=false時の空ベース
    ├── create_daily_base.sql              # 日次: ベースデータ作成 (メアドあり)
    ├── create_daily_base_join_email.sql   # 日次: ベースデータ作成 (メアドなし→JOIN)
    ├── exclude_sent.sql                   # 送信済みデータ除外
    ├── insert_push_log.sql                # 共通送信ログ記録
    ├── insert_google_data_manager_push_log.sql # Google Data Manager送信対象ログ記録
    ├── push_facebook.sql                  # Facebook CAPI フォーマット
    ├── push_yahoo.sql                     # Yahoo Ads フォーマット
    ├── push_line.sql                      # LINE フォーマット
    ├── push_tiktok.sql                    # TikTok フォーマット
    ├── push_google_store_sales.sql        # Google Store Sales フォーマット
    ├── push_google_enhanced_web.sql       # Google Enhanced Web フォーマット
    ├── push_google_data_manager_for_conversions.sql # Google Data Manager for Conversions フォーマット
    ├── push_pinterest.sql                 # Pinterest フォーマット
    ├── push_snapchat.sql                  # Snapchat フォーマット
    └── push_x.sql                         # X (Twitter) 送信対象抽出
├── py_scripts/
│   └── push_x.py                          # X Conversion API 送信（py> で直接API送信）
└── requirements.txt                       # py> タスク用の依存パッケージ
```

## 動作概要

### 毎時送信 (`hourly_push_capi.dig`)

JS-SDK で取得したページビュー/購買データを **1時間ごと** に送信します。

```
毎時実行 → JS-SDKデータ抽出 → 重複排除 → 送信済み除外 → ログ記録 → CAPI送信
```

- 対象: `js_enabled: true` のブランドのみ
- 時間窓: スケジュール時刻の **2時間前〜1時間前** (データ遅延を考慮)
- オーダーID をキーに重複排除・送信済み判定

### 日次補完送信 (`daily_push_capi.dig`)

購買テーブルから **毎日10:00 JST** に未送信分を補完送信します。

```
毎日10:00 → 購買データ抽出 → 重複排除 → 送信済み除外 → ログ記録 → CAPI送信
```

- 対象: **全ブランド** (js_enabled の値に関係なく)
- `js_enabled: true` のブランド → 毎時で送れなかった分の補完
- `js_enabled: false` のブランド → このWFが唯一の送信手段
- 時間窓: 前日1日分 (`TD_INTERVAL -1d`)

### 送信済み管理

- 送信したデータは `capi_push_log` テーブルにオーダーID付きで記録
- 次回送信時に `LEFT JOIN` で突合し、未送信分のみ送信
- hourly / daily 間での二重送信も防止

## 設定方法

### 事前準備

1. **Treasure Data コネクタの作成**: 各プラットフォームの Result Export コネクタを作成（X は不要、下記参照）
2. **出力先データベースの作成**: `config/params.yml` の `common.database` で指定するDB
3. **送信ログテーブルの作成**: `capi_push_log` テーブルを出力先DBに作成
4. **X (Twitter) を使う場合のみ**: `requirements.txt` がプロジェクトルートに配置されていることを確認（`py>` タスクが実行時に自動インストールする）

### config/params.yml の編集

`config/params.yml` がこのワークフローの **唯一の編集対象** です。

#### 共通設定

```yaml
common:
  database: capi_database    # 中間テーブル・ログの出力先DB
  currency: JPY              # 通貨コード (JPY / USD 等)
  timezone: Asia/Tokyo
```

#### ブランド設定

`brand` 配列にブランドを追加します。1つのブランド = 1つの送信先プラットフォームです。
同じブランドを複数プラットフォームに送信する場合は、ブランド名を変えて複数エントリを作成してください。

```yaml
brand:
  - brand_name: my_brand_fb        # テーブル名に使用される識別子
    platform: facebook             # 送信先プラットフォーム
    connector: my_brand_fb_capi    # TDコネクタ名
    ...
```

### パラメータ一覧

#### 基本設定

| パラメータ | 必須 | 説明 | 例 |
|---|---|---|---|
| `brand_name` | Yes | ブランド識別子 (テーブル名に使用、英数字とアンダースコアのみ) | `brand_a` |
| `platform` | Yes | 送信先 (`facebook` / `yahoo` / `line` / `tiktok` / `google_store_sales` / `google_enhanced_web` / `google_data_manager_for_conversions` / `pinterest` / `snapchat` / `x`) | `facebook` |
| `connector` | Yes | TDのResult Exportコネクタ名 | `brand_a_fb_capi` |

#### データソース設定

| パラメータ | 必須 | 説明 | 例 |
|---|---|---|---|
| `js_enabled` | Yes | JS-SDK のデータがあるか (`true` / `false`) | `true` |
| `log_db` | js_enabled=true | JS-SDKログのDB名 | `brand_a_db` |
| `log_tbl` | js_enabled=true | JS-SDKログのテーブル名 | `pageviews` |
| `purchase_db` | Yes | 購買データのDB名 | `brand_a_db` |
| `purchase_tbl` | Yes | 購買データのテーブル名 | `purchases` |

#### メアド設定

| パラメータ | 必須 | 説明 | 例 |
|---|---|---|---|
| `has_email` | Yes | データソースにメアドがあるか (`true` / `false`) | `true` |
| `member_db` | has_email=false | 会員マスタDB | `master_db` |
| `member_tbl` | has_email=false | 会員マスタテーブル | `members` |
| `member_id_col` | has_email=false | 会員マスタの会員IDカラム | `member_id` |
| `member_email_col` | has_email=false | 会員マスタのメアドカラム | `email` |

> **メアドなし (`has_email: false`) の場合**: 会員IDをキーに会員マスタテーブルを LEFT JOIN してメアドを取得します。新規登録直後で会員マスタにメアドが未登録の場合も、レコードは保持されます。

#### JS-SDK カラム名 (毎時送信用)

JS-SDKのカラム名はサイトごとに異なるため、設定で指定します。
**カラムが存在しない場合は `""` (空文字) を設定** → SQL側で `NULL` として出力されます。

| パラメータ | 説明 | 例 | 必須 |
|---|---|---|---|
| `col_order_id` | オーダーID | `transactionid` | Yes |
| `col_email` | メアド (has_email=true時) | `hashedmailaddress` | has_email=true |
| `col_amount` | 売上金額 | `amount` | Yes |
| `col_member_id` | 会員ID | `userid` | Yes |
| `col_phone` | 電話番号 | `hashed_user_global_phone_number` | `""` で省略可 |
| `col_country` | 国コード | `hashed_user_country` | `""` で省略可 |
| `col_user_agent` | ユーザーエージェント | `td_user_agent` | `""` で省略可 |
| `col_ip` | IPアドレス | `td_ip` | `""` で省略可 |
| `col_url` | ページURL | `td_path` | `""` で省略可 |
| `col_fbc` | Facebook Click ID | `fbc` | Facebook以外は `""` |
| `col_fbp` | Facebook Pixel ID | `fbp` | Facebook以外は `""` |

#### 購買データ カラム名 (日次送信用)

| パラメータ | 説明 | 例 | 必須 |
|---|---|---|---|
| `pcol_order_id` | オーダーID | `order_id` | Yes |
| `pcol_email` | メアド (has_email=true時) | `email` | has_email=true |
| `pcol_amount` | 売上金額 | `amount` | Yes |
| `pcol_member_id` | 会員ID | `member_id` | Yes |
| `pcol_time` | TDのUnix秒タイムスタンプカラム（Google送信時にepoch msへ変換） | `time` | Yes |

#### フィルタ条件

| パラメータ | 説明 | 例 |
|---|---|---|
| `cnv_conditions` | JS-SDKデータの抽出条件 (WHERE句に追加) | `"transactionid != '' AND transactionid NOT IN ('undefined')"` |
| `purchase_conditions` | 購買データの抽出条件 (WHERE句に追加) | `"1=1"` (条件なし) |

#### プラットフォーム固有設定

該当しないプラットフォームのパラメータは `""` を設定してください。

| パラメータ | 対象 | 説明 | 例 |
|---|---|---|---|
| `yahoo_ydn_conv_io` | Yahoo | コンバージョンIO | `"12345678"` |
| `yahoo_ydn_conv_label` | Yahoo | コンバージョンラベル | `"abcdef"` |
| `google_conversion_action_id` | Google (既存Store Sales / Enhanced Web) | コンバージョンアクションID | `"123456789"` |
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

### パターン1: JS-SDK + メアドあり (Facebook)

最も一般的なケース。JS-SDKでメアドも取得できる。

```yaml
  - brand_name: brand_a
    platform: facebook
    connector: brand_a_fb_capi
    js_enabled: true
    log_db: brand_a_db
    log_tbl: pageviews
    purchase_db: brand_a_db
    purchase_tbl: purchases
    has_email: true
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
    yahoo_ydn_conv_io: ""
    yahoo_ydn_conv_label: ""
    google_conversion_action_id: ""
```

### パターン2: JS-SDK + メアドなし (LINE)

JSでメアドが取得できないため、会員マスタからJOIN。

```yaml
  - brand_name: brand_b
    platform: line
    connector: brand_b_line_conv
    js_enabled: true
    log_db: brand_b_db
    log_tbl: pageviews
    purchase_db: brand_b_db
    purchase_tbl: purchases
    has_email: false
    member_db: brand_b_master
    member_tbl: members
    member_id_col: member_id
    member_email_col: email
    col_order_id: transactionid
    col_email: ""
    col_amount: amount
    col_member_id: userid
    col_phone: ""
    col_country: ""
    col_user_agent: td_user_agent
    col_ip: td_ip
    col_url: td_path
    col_fbc: ""
    col_fbp: ""
    pcol_order_id: order_id
    pcol_email: ""
    pcol_amount: amount
    pcol_member_id: member_id
    pcol_time: time
    cnv_conditions: "transactionid != ''"
    purchase_conditions: "1=1"
    yahoo_ydn_conv_io: ""
    yahoo_ydn_conv_label: ""
    google_conversion_action_id: ""
```

### パターン3: JS-SDKなし・購買データのみ (Google Store Sales)

JSは使わず、日次の購買データのみで運用。

```yaml
  - brand_name: brand_c
    platform: google_store_sales
    connector: brand_c_google_ss
    js_enabled: false
    log_db: ""
    log_tbl: ""
    purchase_db: brand_c_db
    purchase_tbl: purchases
    has_email: true
    member_db: ""
    member_tbl: ""
    member_id_col: ""
    member_email_col: ""
    col_order_id: ""
    col_email: ""
    col_amount: ""
    col_member_id: ""
    col_phone: ""
    col_country: ""
    col_user_agent: ""
    col_ip: ""
    col_url: ""
    col_fbc: ""
    col_fbp: ""
    pcol_order_id: order_id
    pcol_email: email
    pcol_amount: amount
    pcol_member_id: member_id
    pcol_time: time
    cnv_conditions: ""
    purchase_conditions: "1=1"
    yahoo_ydn_conv_io: ""
    yahoo_ydn_conv_label: ""
    google_conversion_action_id: "123456789"
```

## デプロイ手順

```bash
# 1. プロジェクトディレクトリに移動
cd common_push_capi

# 2. params.yml を編集
vi config/params.yml

# 3. Treasure Data にプッシュ
tdx wf push
```

## 処理フロー詳細

```
1. create_*_base.sql        ベースデータ作成 (capi_base_{brand_name})
   ├─ has_email=true  → データソースから直接メアド取得
   └─ has_email=false → 会員IDで会員マスタをLEFT JOIN
2. exclude_sent.sql         送信済み除外 (capi_send_{brand_name})
3. insert_push_log.sql      送信ログ記録 (Google Data Managerは専用ログSQL)
4. COUNT(*) check           送信件数チェック (0件ならスキップ)
5. push_{platform}.sql      プラットフォーム別フォーマットで送信
```

## 中間テーブル

ワークフロー実行時に以下のテーブルが作成されます（ブランドごと）:

| テーブル名 | 用途 | 永続 |
|---|---|---|
| `capi_base_{brand_name}` | ベースデータ (create_table で毎回上書き) | No |
| `capi_send_{brand_name}` | 送信対象データ (create_table で毎回上書き) | No |
| `capi_push_log` | 送信ログ (insert_into で追記) | **Yes** |

## トラブルシューティング

| 症状 | 原因 | 対処 |
|---|---|---|
| 送信件数が常に0 | 送信済み判定が効きすぎている | `capi_push_log` の該当ブランドのデータを確認 |
| メアドが全て NULL | `has_email` の設定間違い、または会員マスタのJOINキー不一致 | params.yml の `member_*` 設定を確認 |
| 二重送信が発生 | `capi_push_log` テーブルが存在しない | 出力先DBに空テーブルを作成 |
| コネクタエラー | TDコネクタ名の設定間違い、または認証切れ | `connector` の値とTDコンソールのコネクタ名を照合 |
| hourly で何も処理されない | `js_enabled: false` になっている | params.yml の設定を確認 |
| 金額が0や NULL | `col_amount` / `pcol_amount` のカラム名が間違い | 実テーブルのカラム名を確認 |
| X への送信が失敗する（401） | OAuth1.0a認証情報の間違い、またはトークンの権限不足（`AD_MANAGER`/`ACCOUNT_ADMIN` 権限が必要） | `x_consumer_key` 等をDeveloper Portalで再確認 |
| X で計測されない | `x_event_id`（固定値）と `conversion_id`（注文ID）を混同している | `x_event_id` は全送信共通の固定値であることを確認 |

## 注意事項

- **SQLエンジン**: Trino を使用しています（Hive ではありません）
- **タイムゾーン**: JST (Asia/Tokyo) 基準で動作します
- **ハッシュ処理**: 各プラットフォームの TD コネクタが自動でハッシュ・正規化を行います。SQL側で事前ハッシュは不要です
- **送信ログの肥大化**: `capi_push_log` は追記のみのため、長期運用時は定期的なクリーンアップを検討してください

---

<!-- AI_SETUP_INSTRUCTIONS_START -->
## AI向け: 対話的セットアップ手順

> **このセクションは Treasure Studio / Claude Code 等の AI アシスタントが読み取り、対話的に `config/params.yml` を生成するための指示です。人間が直接編集する場合は上記の「設定方法」セクションを参照してください。**

### 前提

このREADME.mdを読み込んだ時点で、AIは以下の対話的セットアップを実行できる。スキルのローカルインストールは不要。

### セットアップフロー

ユーザーがこのリポジトリのCAPI設定を行いたいと言った場合、以下の手順で対話的にヒアリングし、`config/params.yml` を生成する。

#### Step 1: リポジトリ取得

1. GitHub URL からリポジトリをクローン、または `config/params.yml` を取得する
2. 現在の設定内容を把握する

#### Step 2: 対話的ヒアリング

以下の情報を **段階的に** ユーザーに質問する。選択肢を提示し、1回の質問で3〜4項目までに収める。

**2-1. プラットフォーム選択（複数選択可）**

| 選択肢 | platform 値 |
|---|---|
| Meta (Facebook/Instagram) | `facebook` |
| Yahoo 広告 | `yahoo` |
| LINE | `line` |
| TikTok | `tiktok` |
| Google Store Sales | `google_store_sales` |
| Google Enhanced Web | `google_enhanced_web` |
| Google Data Manager for Conversions | `google_data_manager_for_conversions` |
| Pinterest | `pinterest` |
| Snapchat | `snapchat` |
| X (Twitter) | `x` |

**X を選択した場合の注意:** X にはTDのResult Exportコネクタが存在しないため、`connector` は不要（`""` のままでよい）。`py>` オペレーターが `py_scripts/push_x.py` を実行し、X Ads API へ直接送信する。

**2-2. ブランド基本情報（プラットフォームごとに）**

- `brand_name`: ブランド識別子（英数字と_のみ。テーブル名に使用）
- `connector`: TDのResult Exportコネクタ名

**2-3. データソース設定**

- JS-SDK のデータがあるか？ → `js_enabled: true/false`
- `js_enabled: true` → `log_db`, `log_tbl` を質問
- 全ブランド共通で `purchase_db`, `purchase_tbl` を質問

**2-4. テーブルスキーマ確認とカラム自動提案**

DB名・テーブル名が確定したら、**ユーザーに許可を得た上で** 以下のコマンドを実行し、スキーマとサンプルデータを取得する:

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
| `pcol_time` | `time`, `timestamp`, `created`, `date` を含む | TDのUnix秒タイムスタンプ（日時文字列は事前変換が必要） |

**提案フォーマット:**

スキーマとサンプルデータの分析結果をもとに、以下の形式で提案する:

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
  col_member_id → userid          (理由: "user"を含むIDカラム)
  col_phone     → (該当なし)      → "" に設定
  col_country   → (該当なし)      → "" に設定
  ...

この提案でよろしいですか？修正があれば指定してください。
```

**重要:**
- 提案はあくまで推定であり、**ユーザーの修正・上書きを常に受け付ける**
- 推定に自信がない場合は複数の候補を提示し、ユーザーに選択してもらう
- 該当カラムが見つからない場合は `""` (NULL出力) を提案する
- 購買テーブル、JS-SDKテーブル、会員マスタテーブルそれぞれに対して実行する
- `has_email` の判定もスキーマから推定可能: メアドらしいカラムがなければ `has_email: false` を提案

**2-5. メアド設定**

Step 2-4 のスキーマ確認結果をもとに:
- メアドカラムが見つかった場合 → `has_email: true` を提案
- 見つからない場合 → `has_email: false` を提案し、会員マスタの情報を質問
  - `member_db`, `member_tbl` を質問
  - 会員マスタも `tdx describe` でスキーマ確認し、`member_id_col`, `member_email_col` を提案

**2-6. カラムマッピング確定**

Step 2-4 の提案をユーザーが確認・修正した結果を最終的なカラムマッピングとして確定する。

確定するパラメータ:

JS-SDK カラム（`js_enabled: true` の場合）:
`col_order_id`, `col_email`, `col_amount`, `col_member_id`, `col_phone`, `col_country`, `col_user_agent`, `col_ip`, `col_url`, `col_fbc`, `col_fbp`

購買データカラム:
`pcol_order_id`, `pcol_email`, `pcol_amount`, `pcol_member_id`, `pcol_time`

**2-7. フィルタ条件**

サンプルデータを参考に、フィルタ条件も提案する:
- `cnv_conditions`: 例えばオーダーIDに `undefined` や空文字が混在している場合 → `"transactionid != '' AND transactionid NOT IN ('undefined')"` を提案
- `purchase_conditions`: 通常は `"1=1"` を提案。特殊な条件があればサンプルデータから推定

**2-8. プラットフォーム固有設定**

- Yahoo → `yahoo_ydn_conv_io`, `yahoo_ydn_conv_label` を質問
- Google (既存Store Sales / Enhanced Web) → `google_conversion_action_id` を質問
- Google Data Manager for Conversions → `google_dm_conversion_type`, `google_dm_operating_account_id`, `google_dm_login_account_id`（MCC経由時のみ）, `google_dm_conversion_action_id`, `google_dm_event_source`（OFFLINE時）, `google_dm_store_id`（STORE_SALES時）, 同意設定、無効レコード・ステータス待機設定を質問
- X (Twitter) → `x_pixel_id`（Events Managerで発行）, `x_event_id`（Events Managerで作成した固定イベントID。注文IDではない点に注意）, `x_consumer_key`, `x_consumer_secret`, `x_access_token`, `x_access_token_secret`（Developer Portal で発行するOAuth1.0a認証情報）を質問
- その他 → 該当パラメータは `""` を自動設定

**2-9. 共通設定**

- `common.database`: 中間テーブル・ログの出力先DB（デフォルト: `capi_database`）
- `common.currency`: 通貨コード（デフォルト: `JPY`）

#### Step 3: params.yml 生成

収集した情報から `config/params.yml` を生成する。

**生成ルール:**
- 存在しないカラムは必ず `""` (空文字) にする
- プラットフォームに関係ないパラメータも `""` で必ず含める（全ブランドが同じキー構造を持つこと）
- コメントで各セクションを説明する
- 設定例のコメントアウトされたブランドは削除し、実際のブランド設定のみ出力する

**キー構造（全ブランド共通）:**
```yaml
brand:
  - brand_name: ""
    platform: ""
    connector: ""
    js_enabled: false
    log_db: ""
    log_tbl: ""
    purchase_db: ""
    purchase_tbl: ""
    has_email: true
    member_db: ""
    member_tbl: ""
    member_id_col: ""
    member_email_col: ""
    col_order_id: ""
    col_email: ""
    col_amount: ""
    col_member_id: ""
    col_phone: ""
    col_country: ""
    col_user_agent: ""
    col_ip: ""
    col_url: ""
    col_fbc: ""
    col_fbp: ""
    pcol_order_id: ""
    pcol_email: ""
    pcol_amount: ""
    pcol_member_id: ""
    pcol_time: ""
    cnv_conditions: "1=1"
    purchase_conditions: "1=1"
    yahoo_ydn_conv_io: ""
    yahoo_ydn_conv_label: ""
    google_conversion_action_id: ""
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

#### Step 4: 確認・修正

生成した `params.yml` をユーザーに提示し、修正点がないか確認する。

#### Step 5: デプロイ

```bash
cd common_push_capi
tdx wf push
```

### ヒアリングのコツ

- **スキーマ確認を積極的に行う**: DB・テーブル名が確定したら必ず `tdx describe` と サンプルクエリを実行して提案の精度を上げる
- **提案は修正前提で提示する**: 「この提案でよろしいですか？修正があれば指定してください」と必ず確認する
- **1回の質問で多くを聞きすぎない**: 3〜4項目ずつグルーピングする
- **デフォルト値を提示する**: ユーザーが迷わないように典型的な値を示す
- **選択肢で絞り込む**: 自由入力より選択肢を優先する
- **複数ブランドの場合**: 1ブランド目を詳細に設定し、2ブランド目以降は差分のみ質問する
- **同じブランドを複数プラットフォームに送信する場合**: brand_name を `{brand}_{platform}` の形式で区別する
<!-- AI_SETUP_INSTRUCTIONS_END -->
