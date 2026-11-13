# CAPI ワークフロー実装 Tips

他案件での実装経験から得られた注意点・ハマりポイントをまとめます。

---

## 1. SQL テンプレート展開時の空カラム問題

### 問題
`CASE WHEN '${b.col_phone}' \!= '' THEN ${b.col_phone} ELSE NULL END` パターンで、
値が空文字 `""` の場合に `THEN` の後が空になり構文エラーが発生する。

```sql
-- col_phone: "" の場合、以下のように展開される
CASE WHEN '' \!= '' THEN  ELSE NULL END
--                  ^^^^^ ← 式がない！
```

### 対策
**空カラムは `CASE WHEN` による動的分岐をやめ、`CAST(NULL AS VARCHAR)` に固定する。**
現在の実装では `common` にカラム設定を集約し、存在するカラムは直接参照、
存在しないカラムは `CAST(NULL AS VARCHAR)` で固定している。
空文字の任意カラム（phone, country, fbc, fbp, ly_*, line_uid, ifa, referrer 等）は、
`NULL` として出力される。

---

## 2. 金額カラムの型変換

### 問題
金額カラム（`csubtotal` 等）が `'75900.00'` のようにVARCHAR型の小数値の場合、
`CAST(raw_amount AS BIGINT)` で直接変換するとエラーになる。

```
Cannot cast '75900.00' to BIGINT
```

### 対策
**2段階キャスト: `CAST(CAST(raw_amount AS DOUBLE) AS BIGINT)`**

VARCHAR → DOUBLE → BIGINT の順で変換し、小数を切り捨てて整数化する。

ただし、この整数化は **小数を切り捨てる** ため、Yahoo / OpenAI では金額の精度が失われます。
そのため、次のように分けています。

- 従来媒体: 整数の `value`（BIGINT）をそのまま使う（変更なし）
- Yahoo / LINE: `value_decimal` を `custom_value` として送る（小数を保持）
- OpenAI: `value_decimal` × `openai_amount_multiplier` を minor unit の整数にして `data_amount` として送る

---

## 3. 初回実行時の capi_push_log 未存在

### 問題
初回実行時は `capi_push_log` テーブルが存在しないため、
LEFT JOINを含むSQLがテーブル不在エラーになる。

### 対策
- **`check_push_log_exists.sql`**: `information_schema.tables` でテーブル存在を確認する。ブランドごとに実行し、結果を `store_last_results` で受け取る
- **`stage_brand_initial.sql`**: テーブルがないとき、JOINなしで全件を未送信として抽出する
- **`stage_brand.sql`**: テーブルがあるとき、`brand_name` + `platform` で送信済みを除外する

存在確認はブランドごとのタスクの中で行う。`td.last_results` は直前の `store_last_results` で上書きされるため、`_export` や別のループの外側に置くと値が失われる。

注意: 初回でも `insert_into` の先の `capi_push_log` は必要です。README の手順どおり、空のテーブルを先に作成してください。

---

## 4. digdag の `_export` 変数スコープ

### 問題
digdagの `_export` はトップレベルのステップでは後続タスクに変数を伝播しない。
`store_last_results` の値を後で使いたい場合、`_export` で保存してもスコープ外でundefinedになる。

```yaml
# これは動かない
+save_var:
  _export:
    my_var: ${td.last_results.value}
+use_var:
  if>: ${my_var > 0}  # ReferenceError: "my_var" is not defined
```

### 対策
**`_export` ではなく、SQLクエリ自体に存在確認ロジックを組み込む。**
`check_push_log_exists.sql` のように、存在確認は独立したタスクにし、`store_last_results` で結果を受け渡す。ブランドごとの処理の中で実行する。

---

## 5. TikTok コネクタの必須カラム名

### 問題
TikTok Events API コネクタ（`embulk-output-tiktok_events`）は `event_time` という
**カラム名を必須**で要求する。`AS timestamp` 等にリネームするとエラーになる。

```
The column event_time is required
```

### 対策
**`CAST(event_time AS BIGINT) AS event_time`** — カラム名を維持したまま型変換のみ行う。

また、`result_settings` に以下が必要:
```yaml
result_settings:
  skip_invalid_record: true
  event_source: ${b.tiktok_event_data_source}     # WEB / APP
  event_source_id: ${b.tiktok_event_source_id}     # ピクセルID
```

---

## 6. LINE 広告は yahoo_conversion_v2 に統合

### 旧方式の問題
以前は LINE Conversion API コネクタに対して `result_settings` で `line_tag_id` と `access_token` を
渡していた。認証情報を `params.yml` に置く必要があり、Yahoo とは別の送信経路だった。

### 現行の対策
LINE 広告も **Yahoo Ads Conversion Export v2 コネクタ（`yahoo_conversion_v2`）** を使う。

- `platform: line` のブランドは、Yahoo と同じコネクタ種別で、設定を別々に持つ
- 認証情報（`tag_access_token`）はコネクタ側に保存し、`params.yml` には置かない
- LINE の識別子 `line_uid` を送る場合は `channel_id` が必須。`channel_id` が空なら、`line_uid` は送信データから外れる
- 旧キー `line_tag_id` / `line_access_token` は削除済み（README の移行表を参照）

```yaml
brand:
  - brand_name: brand_line
    platform: line
    connector: brand_line_conv_v2
    tag_id: "87654321"
    channel_id: "1234567890"     # line_uid を送るため必須
```

---

## 7. Google Enhanced Conversions の conversion_type

### 問題
Google Enhanced Conversions コネクタはデフォルトで `upload_offline_click_conversion` として動作し、
`gclid` / `gbraid` / `wbraid` のいずれかを必須とする。

```
Please specify one of column gbraid, wbraid or gclid
```

### 対策
`result_settings` で `conversion_type` を明示的に指定する。

| メソッド | conversion_type | 必須カラム |
|---|---|---|
| Store Sales | `upload_store_sales` | `tran_datetime`, `tran_amount`, `tran_currency` |
| Enhanced for Web | `upload_enhanced_for_web` | `order_id`, `conversion_action_id` |
| Offline Click | `upload_offline_click_conversion` | `gclid` + `conversion_date_time`, `conversion_value`, `currency_code` |
| Enhanced for Lead | `upload_enhanced_for_lead` | - |
| Call Conversion | `upload_call_conversion` | - |

**Store Sales と Enhanced Web ではカラム名が異なる点に注意。**

---

## 8. Google customer_id の型

### 問題
`customer_id` が文字列として渡されると `Customer is not a number` エラーが発生する。

### 対策
`result_settings` の `customer_id` にはハイフンなしの**数値文字列**を指定する。

---

## 9. 送信ログの記録タイミングと対象

### 問題
あるPFの送信がエラーになった場合、既に成功した他のPFを再送信してしまう。

### 対策
**送信ログ記録（`insert_*`）を送信の後に配置。**

```
check_push_log → stage_brand → check_count → skip_or_send → [PF送信] → 送信ログ記録
```

- 送信成功 → ログ記録 → 次回スキップ
- 送信失敗 → ログ未記録 → 次回リトライ
- Yahoo / LINE / OpenAI は、**送信対象テーブルに格納された行だけ** を送信し、同じ行だけをログへ記録する。送信対象外の行をログに残さない
- Google Data Manager は、送信SQLと同じ適格条件を専用ログSQLにも適用し、SQLで除外した行を記録しない
- 従来媒体（メアドで送信する媒体）は、`insert_push_log.sql` が送信SQLと同じ条件（`em` が空でない）で絞った行だけを記録する（TIPS 18）

---

## 10. params.yml の構造設計

### 旧構造の問題
- `has_email` が1つしかなく、Webログと購買ログで別々に設定できない
- PF固有設定が全ブランドに冗長に含まれる
- 空文字カラムが `CASE WHEN` で展開エラーを起こす

### 現行の構造
```yaml
common:          # データソース・カラム設定（全PF共通）
  js_has_email:       # Webログのメアド有無
  purchase_has_email: # 購買ログのメアド有無
  member_db / member_tbl / member_id_col / member_email_col   # 4つがすべて揃った場合のみ会員マスタを JOIN

brand:           # PF別送信先設定（そのPFに必要な設定のみ）
  - brand_name: xxx
    platform: yahoo           # 許可リストの値のみ
    connector: xxx
    tag_id: "..."             # Yahoo / LINE 固有
```

**ベースデータは1回だけ作成し、各PF送信時にSQLでリネーム・フィルタする。**
Yahoo / LINE / OpenAI は、ベースから自分の送信対象テーブルへ行を抽出し、その行だけを送信する。

---

## 11. X (Twitter) はコネクタなし、`py>` で直接API送信

### 問題
X (Twitter) Ads API にはTDのResult Exportコネクタが存在しない。
他PFと同じ `td>` + `result_connection` パターンが使えない。

### 対策
`py_scripts/push_x.py` を作成し、`py>` オペレーターで直接 X Ads API
(`POST /12/measurement/conversions/:pixel_id`) にリクエストする。
認証は OAuth 1.0a（`requests_oauthlib.OAuth1`）で、Consumer Key/Secret と
Access Token/Secret の4点が必要。`requirements.txt` をプロジェクトルートに
配置し、`py>` タスク内で実行時にインストールする（TD の py> はDocker起動時に
自動でrequirements.txtを読まないため、スクリプト冒頭で明示的にpip installする）。

### `event_id` と `conversion_id` の混同に注意
X APIの `event_id` は Events Manager で作成した**固定の**イベントIDで、
全リクエストで同じ1つの値を使う。TD側のオーダーID（他PFの `event_id` カラムに相当する値）は
`conversion_id` として送信し、Pixel側の重複排除キーとして使われる。
ここを混同すると、Xの計測画面で正しくコンバージョンが認識されない。

### 識別子のハッシュ・正規化ルール
- メールアドレス: SHA256（**ソルトなし**、小文字化・trimしてからハッシュ）
- 電話番号: E.164形式（`+`付き国番号）に正規化した後にSHA256ハッシュ
- `email_hashed` / `phone_hashed` が既に `true`（会員テーブル等で事前ハッシュ済み）の場合は二重ハッシュしない
- メール・電話のいずれか1つ以上の識別子が必須（IP+UAだけでは不十分な場合がある）

### レート制限
60,000イベント/アカウント/15分。大量データを一度に流す場合は
1000件程度のバッチに分割してリクエストする。

### 注意: X の OAuth 値の保管
現行の設計では X の OAuth 値を `params.yml` に記載する。このファイルを Git で管理する場合は、
リポジトリの公開範囲とアクセス権を確認すること（Yahoo / OpenAI の認証情報は `params.yml` に置かない）。

---

## 12. Google Data Manager for Conversions のイベント種別

### 問題
Google Data Managerにはオーディエンスリスト用とコンバージョン用の別コネクタがあり、
さらにコンバージョン用では `OFFLINE` / `ONLINE` / `STORE_SALES` ごとに必須項目が異なる。

### 対策
Integration Hubで **Google Data Manager for Conversions** コネクタを作成し、
`platform: google_data_manager_for_conversions` を指定する。

| conversion_type | 必須項目 |
|---|---|
| `OFFLINE` | `event_timestamp`, `event_source`, 識別子 |
| `ONLINE` | `event_timestamp`, `transaction_id`, 識別子 |
| `STORE_SALES` | `event_timestamp`, `transaction_id`, `conversion_value`, `currency`, `store_id`, PII識別子 |

この汎用WFでは `event_time` をTDのUnix秒に統一する。送信SQLでは
`CAST(event_time AS BIGINT) * 1000` としてData Managerが受け付けるepoch millisecondsへ変換する。
日時文字列や既にepoch millisecondsのカラムは、共通ベースに入れる前にUnix秒へ変換する。

現在の共通ベースがGoogle Data Managerへ渡す識別子はURL内の
`gclid` / `gbraid` / `wbraid` / `dclid`、email、IPで、`STORE_SALES` は
email必須・日次WFのみとする。phone / address / mobile device ID等を使う場合は
共通ベースと送信SQLの両方へカラムを追加する。

`waiting_for_request_status: false` の場合、受付後の最終処理結果を待たずに送信タスクが完了する。
不正レコードを送信済みログへ残さないため、通常は `skip_invalid_records: false` を使用する。
毎時WFでは長時間のブロックを避けるため `waiting_for_request_status: false` を標準とし、
送信ログはGoogleのリクエスト受付成功を表す。最終処理結果まで同期確認する必要がある場合のみ
`true` にする（Google側の処理完了までタスクが長時間待機する可能性がある）。

---

## 13. 外部SQLファイルの不等号はエスケープしない

`.dig` 内の式ではなく `query/*.sql` に記述する不等号は、Trinoへそのまま送られる。
`\!=` と書くとバックスラッシュもSQLに含まれて構文エラーになるため、必ず `!=` を使用する。

---

## 14. Yahoo / LINE（yahoo_conversion_v2）の仕様

### 必須と制限
- `event_type` と `event_time` は必須。`event_time` は Unix 秒の10桁（13桁のミリ秒は使わない。ベースは秒で持つ）。Yahoo 側は直近90日以内のイベントのみ受け付ける
- 識別子は1つ以上必須（`ly_su` / `ly_c` / `ly_r` / `line_uid` / `hashed_email` / `hashed_phone_number` / `ifa`）
- `transaction_id` は最大64文字。使用できる文字は英数字と `-_.!~*'();/?:@&=+$,%#`
- `custom_currency` は JPY または USD のみ（大文字小文字は区別しない）
- `line_uid` を送る行には `channel_id` が必要（`channel_id` がなければ、ワークフローは `line_uid` を外す）

### event_type
Yahoo の許容値に従う: `page_view` / `view_listing` / `view_product` / `view_cart` / `add_cart` / `search` / `check_out` / `purchase` / `generate_lead` / `login` / `reservation` / `sign_up` / `payment_info` / `add_wishlist`。
購買データは `purchase` を使う。テンプレートや TD のサンプルの値（他の名前）をそのまま使わない。

### 識別子の値
- `ly_su`: `_ly_su` Cookie の値を、そのまま渡す（`タイムスタンプ.サイトユーザーID` 形式）
- `ly_c`: `_ly_c` Cookie の値はそのまま。**URL パラメータ由来の値は、先頭にタイムスタンプと `.` を付けてから渡す**（Yahoo の仕様）。`<timestamp>.<id>` の形式に合わない値は `prepare_yahoo_v2.sql` で空欄にする（行は他の識別子で送れる場合のみ残す）
- `ly_r`: `_ly_r` Cookie の値（`タイムスタンプ.乱数` 形式）
- `ifa`: IDFA は大文字、AAID は小文字
- `hashed_email` / `hashed_phone_number`: 生値でも SHA-256 のハッシュ値（64桁 hex）でも可。生値は連携側でハッシュ化される。電話番号は国際形式（`+81...`）で渡すことを推奨（TD 側の正規化仕様は未記載）。生値はハイフン・スペース等を除去し、数字と先頭の `+` のみ送る（`prepare_yahoo_v2.sql`）

---

## 15. OpenAI の仕様

### 必須と制限
- `event_id`: 注文IDなど、**安定した一意の値**。再送しても同じ値を使う（重複排除に使われる）
- `event_timestamp`: **ミリ秒**（ベースは秒で持つので、送信時に1000倍する）。過去7日以内、未来は10分以内
- `action_source = web` の行は `source_url` が必須で、http(s) の URL でなければならない
- `data_amount`: minor unit の整数。`data_currency` は ISO 4217 の3文字コードが必要
- `skip_invalid_records`: TD の既定は `true`。推奨は `false`（16 を参照）

### 金額と倍率
- `data_amount` = `value_decimal` × `openai_amount_multiplier`（minor unit に換算し、`ROUND` で四捨五入して整数化）
- JPY は `1`、USD は `100`。**他通貨を `100` と推測しない**。通貨ごとに最小単位を確認し、倍率を明示的に設定する
- 倍率と `common.currency` が一致していないと、金額が桁違いになる（ワークフローは倍率が正の値であることを検証する）
- 端数（minor unit 未満）の丸め規則は SQL 側で固定し、ブランドごとに変えない

### action_source
- 毎時（JS-SDK）データ: `openai_action_source`（既定 `web`）。URL（`col_url`）が必要
- 日次（購買）データ: `openai_daily_action_source`。実際の発生元に合わせて `offline` か `web` を選ぶ。`web` の場合は `pcol_url` が必要
- 1つの OpenAI ブランドで毎時と日次の両方を送る。ブランドを分ける必要はない

### 識別子と対象外
- メアド・電話番号・会員ID（`external_id`）は生値でも 64 桁 hex でも可。コネクタが正規化してハッシュ化する
- `obref`（`col_obref`）は、値があり、かつ測定の同意がある場合のみ送る。同意を推測して既定値にしない
- `oppref`（`col_oppref`）は値をそのまま渡す
- IDFA は送らない。GAID（Android の広告ID）はテンプレートでマッピングしていない。`ifa` は Yahoo 専用
- テンプレートが対応する `event_type` は `order_created` のみ

---

## 16. skip_invalid_records と stop_on_batch_failure の推奨値

### 問題
送信後に `capi_push_log` へ記録する仕組みでは、コネクタが不正レコードを黙って読み飛ばすと、
その行は「送信済み」として記録されてしまう。次回以降は再送されない。

### 対策
- `skip_invalid_records: false` を推奨する。不正行はエラーとして表に出し、ログとの整合を保つ
- `stop_on_batch_failure: true` を推奨する。バッチが失敗したら後続バッチを止め、送られていない行を広げない

ログは「実際に送信対象として格納された行」と同じ集合に対して記録する。ただし、コネクタが部分的に受け付けた場合の扱いは、
コネクタの仕様に依存する。`skip_invalid_records` を `true` にする場合は、不正行が送信済み扱いになることを理解したうえで決める。

---

## 17. test_flag: true の扱い

- `test_flag: true` の Yahoo / LINE ブランドのエクスポートは、**送信ログ（`capi_push_log`）に記録しない**
- これは意図した動作。テスト送信を本番の送信済み判定に混ぜないため
- 本番に切り替えたら `test_flag: false` に戻す。テスト中の行は本番送信の対象として残る

---

## 18. 送信済み判定はブランド・媒体ごとに行う

### 問題
送信済みを `event_id` だけで判定していたため、次の問題があった。
- 同じ注文を複数のブランドへ送ると、先に記録されたブランドの影響で後のブランドが対象外になる（ワークフローを最初から再実行したときに起きやすい）
- 従来媒体は、送信SQLの条件で除外された行（メアドなし等）も送信済みとして記録していた

### 対策
- 送信ログは `brand_name` + `platform` + `event_id` で判定する（`stage_brand.sql`）
- ブランドごとに未送信の行を `capi_send` に抽出してから、その媒体へ送信する
- 従来媒体は、送信SQLと同じ条件（メアドあり）を通過した行だけを `insert_push_log.sql` で記録する
- `platform` が空の旧ログ行は `brand_name` で一致させ、移行後に再送しない
- 送信ログの記録は送信の後（TIPS 9）。送信が失敗した場合は記録されず、次回の対象になる

### 残る制約
- **コネクタが読み飛ばした行は判別できない**: `skip_invalid_records: true` でコネクタが読み飛ばした行も、TD からは送信済みとして記録される。Yahoo / LINE / OpenAI は送信前に検証して対象外の行を除くが、従来媒体は各コネクタの仕様に依存する（TIPS 16）
- **移行前の記録**: 移行前に送信対象外として記録された行は、そのブランドでは以後も対象外のまま（README「送信ログテーブルの移行」の任意の整理を参照）
- **移行順序**: 両スケジュールの停止 → 実行中attemptの完了待ち → スキーマ変更・確認 → 無効のまま新版デプロイ → 検証 → 別途承認後の再開。旧版の実行中に列を追加しない
- **送信済みの意味**: SQLの適格条件を通った入力行集合を、エクスポートタスク成功後に記録する。媒体側の行別受領やexactly-once配信を保証するログではない
- **ブランド名の付け方**: 新形式の履歴は `brand_name` + `platform` で分離する。ただし旧 `platform IS NULL` 履歴は同じブランドの全媒体へ適用される。旧ブランド名を別媒体へ流用しない。旧設定から送信先を確定して履歴を補完できない場合は、媒体別の新しいブランド名を使う
- **同時実行**: hourly と daily が同時に `capi_base` / `capi_send` を作り直すと、互いの中間テーブルを壊す可能性がある。実行時刻をずらして運用する

---

## 19. dig の三項演算子は引用符で囲む

`${a ? b : c}` のように三項演算子を引用符なしで書くと、`tdx wf push` がサーバー側で失敗する。
`--dry-run` ではこのエラーを検出できないことがある。三項演算子を含む式は引用符で囲んで書き、push 後に実行前の確認を行う。

---

## 20. 会員マスタ JOIN の条件

会員マスタの JOIN は、`member_db` / `member_tbl` / `member_id_col` / `member_email_col` の4つがすべて設定されている場合のみ行う。
1つでも空なら JOIN せず、メアドは `NULL` になる。メアドを使わずに識別子（`ly_*` / `line_uid`）で送る設計では、JOIN を設定しなくてもよい。


