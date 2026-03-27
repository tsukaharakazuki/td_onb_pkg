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
存在しないカラム（phone, country, fbc, fbp等）は `CAST(NULL AS VARCHAR)` で固定している。

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

---

## 3. 初回実行時の capi_push_log 未存在

### 問題
初回実行時は `capi_push_log` テーブルが存在しないため、
LEFT JOINやINNER JOINを含むSQLがテーブル不在エラーになる。

### 対策
- **`check_push_log_exists.sql`**: `information_schema.tables` でテーブル存在を確認
- **`exclude_sent_initial.sql`**: 初回用、JOINなしで全件を送信対象にコピー
- **`check_brand_sent.sql`**: テーブル存在確認を SQL 内に組み込み（UNION ALL パターン）

```sql
-- テーブルありの場合のクエリ
SELECT COALESCE((...), 0) AS already_sent
WHERE (SELECT COUNT(*) FROM information_schema.tables ...) > 0
UNION ALL
-- テーブルなしの場合は 0 を返す
SELECT 0 AS already_sent
WHERE (SELECT COUNT(*) FROM information_schema.tables ...) = 0
```

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
`check_brand_sent.sql` のように、1つのSQLで `information_schema` チェックと
ブランド別チェックを UNION ALL で組み合わせる。

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

## 6. LINE コネクタの認証設定

### 問題
LINE Conversion API コネクタはコネクタの認証情報だけでは動作せず、
`result_settings` で `line_tag_id` と `access_token` を渡す必要がある。

### 対策
```yaml
result_settings:
  line_tag_id: ${b.line_tag_id}
  access_token: ${b.line_access_token}
  ignore_invalid_records: true
```
params.yml のブランド設定に `line_tag_id` と `line_access_token` を記載する。

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

## 9. リトライ時のPFスキップ設計

### 問題
あるPFの送信がエラーになった場合、既に成功した他のPFを再送信してしまう。

### 対策
**送信ログ記録（`insert_push_log`）を送信の後に配置。**

```
check_brand_sent → skip_or_send → [PF送信] → insert_push_log
```

- 送信成功 → ログ記録 → 次回スキップ
- 送信失敗 → ログ未記録 → 次回リトライ

---

## 10. params.yml の構造設計

### 旧構造の問題
- `has_email` が1つしかなく、Webログと購買ログで別々に設定できない
- PF固有設定が全ブランドに冗長に含まれる
- 空文字カラムが `CASE WHEN` で展開エラーを起こす

### 新構造
```yaml
common:          # データソース・カラム設定（全PF共通）
  js_has_email:       # Webログのメアド有無
  purchase_has_email: # 購買ログのメアド有無

brand:           # PF別送信先設定（そのPFに必要な設定のみ）
  - brand_name: xxx
    platform: facebook
    connector: xxx
    fb_test_event_code: ""  # Facebook固有のみ
```

**ベースデータは1回だけ作成し、各PF送信時にSQLでリネーム・フィルタする。**
