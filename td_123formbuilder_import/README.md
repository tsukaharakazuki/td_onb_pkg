# td_123formbuilder_import

123FormBuilder API v2からフォーム・グループ・ユーザー・投稿をTreasure Dataへ取り込むWorkflow。

## 2026-11-25 修正

従来版はpytdのimport失敗・TD書込失敗・APIの部分失敗を握りつぶし、`+store_*`の固定文を表示していました。修正版は固定成功メッセージとstdoutへのデータ退避を廃止しています。

1. `td_ddl>`で対象テーブルを事前作成（既存なら維持）。DB自体は事前作成が必要。
2. Custom Script内で`requirements.txt`をインストールしてから、requests・pytd・pandasをimport。
3. 公開Swaggerどおり`POST /token`のqueryでログインし、GET時に`JWT` queryを指定。
4. APIから全データを取得。途中のエラーは伝播し、取得完了前にはTDへ書き込まない。
5. `bulk_import`のappendでTDへ保存。
6. `import_run_id`と`time`で今回分の件数をSELECTし、取得件数と一致した場合だけ`IMPORT_SUCCESS`を表示。

実行イメージは`treasuredata/customscript-python:3.12.11-td4`。スケジュールは無効のままです。

## 設定（最初に確認）

`config/params.yml`を編集してください。`-p`による実行時上書きは使いません。

```yaml
td:
  database: 実際の取り込み先DB
  endpoint: api.treasuredata.com  # US。Tokyoはapi.treasuredata.co.jp
formbuilder_base_url: https://api.123formbuilder.com/v2
```

- APIリージョンは`td_ddl>`とPythonで共通です。見ているConsoleと同じアカウント・リージョンか確認してください。
- 123FormBuilder EUは`https://eu-api.123formbuilder.com/v2`。
- Secrets: `formbuilder_username` / `formbuilder_password` / **`td.apikey`**（`td_apikey`ではない）。ファイルに値を記載しないでください。
- `td.apikey`には、テーブル作成・bulk import・検証用Trino SELECTの権限が必要です。
- Secretsは各`py>`の`_env`に直接展開します。

## 構成

- `td_forms.dig` → `formbuilder_forms`
- `td_groups.dig` → `formbuilder_groups`
- `td_users.dig` → `formbuilder_users`
- `td_submissions.dig` → `formbuilder_submissions`
- `pyscript/common.py`: 依存関係導入・API通信・TD書込・件数照合
- `pyscript/*_fetcher.py`: リソース別の取得処理
- `tests/test_import.py`: 外部通信なしのモックテスト
- `tdx.json`: pushするプロジェクト名

## ログの判定

```text
IMPORT_START target=your_db.formbuilder_groups fetched=10 run_id=...
IMPORT_SUCCESS target=your_db.formbuilder_groups fetched=10 verified=10 run_id=...
```

- 成功は`IMPORT_SUCCESS`で判定します。`IMPORT_FAILED`ならWFも失敗します。
- 取り込み対象全体が0件の場合は明示的に失敗させます。元データが本当に0件か、権限により見えないかを確認してください。投稿0件のフォームが混在する場合は、そのフォームだけをスキップし、他のフォームの取得を続けます。
- HTTP/APIエラーはステータスを表示し、認証情報付きURLやレスポンス全文・回答データはログへ出しません。
- 件数照合は最大6回（不一致時10秒待機）。各回でtimeを指定した小範囲SELECTを実行し、TDのクエリ負荷・費用が発生します。
- **書込完了後に検証が失敗する場合もあります。再実行前に`run_id`の取込済データを確認してください。** 全件appendなので、無条件の再実行は重複します。

## データ形式と旧版との差分

- `time`: 取得処理後のUNIX秒（投稿日時ではありません）。pytd自体もtime省略時に自動付与しますが、本WFでは検証用に明示。
- `extracted_at`: UTCのISO日時。旧版のNULLを修正。
- `import_run_id`: 1回のロードを識別するUUID。検証で使用。
- NULLを含む整数はpandasのfloat推論を避け、符号付き64bit整数として保持。64bitを超える整数・精度損失を起こす混合型は文字列として保持します。
- パスワード等の認証情報は前後の空白も変更せず使用します。
- APIのトップレベル項目は維持し、配列・オブジェクトは**JSON文字列**で格納。旧版の`json_normalize`によるドット付き列の展開は行いません。既存BI等で旧列を参照していた場合は移行が必要です。既存データの削除はしません。
- Groups APIの`data.forms`、Fields APIの`data.controls.data`を公式のレスポンス構造に合わせて読み取ります。
- Usersは仕様にある`GET /users`のみ使用。未定義の`GET /user`・`GET /users/{id}`を廃止。推測の`user_type`ではなく`user_parent`等の返却値を維持。
- Submissionsは`submission_data`（全体JSON）、`submission_content`（APIのcontent）、`submission_date`を保存。回答項目の列展開はしません。取得不能なフォーム作成・更新日時の旧NULL列は生成しません。`form_status`はAPIの`active`値です。

**すべて全件取得＋追記のままです。** 増分化・洗い替えは本修正に含みません。大量データは全件をメモリに保持するため分割設計が別途必要です。

## 反映・検証

修正版は`.dig`だけでなく**フォルダ一式**をアップロードしてください。

- フォルダを指定した`tdx wf push`等で反映。アカウント/profileは切り替えないでください。
- WF実行はdry-runで対象を確認し、人の承認後に実行してください。
- この修正の検証はモックと静的チェックのみ。実API・TD上の成功は未確認です。
- 通知メールは未実装です（`_error`はログ表示のみ）。

参照: https://www.123formbuilder.com/developer/api-v2/ および同ページの公開Swagger（swagger-4.json、2024/01掲載）。

Generated with Treasure Work.
