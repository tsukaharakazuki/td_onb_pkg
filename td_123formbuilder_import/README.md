# td_123formbuilder_import

123FormBuilder（API v2）からフォーム・グループ・ユーザー・フォーム投稿（submissions）を取得し、Treasure Data のテーブルに取り込む Workflow です。4 つの WF はそれぞれ独立して実行します。

> ⚠ **既知の課題があります**（後述「既知の課題」）。認証まわりが API 仕様と合っていないため、修正前に本番で実行すると失敗する可能性があります。

## 構成

```
td_123formbuilder_import/
├── tdx.json                  # tdx wf push 用（workflow_project）
├── td_forms.dig              # フォーム情報   → formbuilder_forms
├── td_groups.dig             # グループ情報   → formbuilder_groups
├── td_users.dig              # ユーザー情報   → formbuilder_users
├── td_submissions.dig        # フォーム投稿   → formbuilder_submissions
├── config/
│   └── params.yml            # 取り込み先データベース（td.database）
├── pyscript/
│   ├── forms_fetcher.py
│   ├── groups_fetcher.py
│   ├── users_fetcher.py
│   └── submissions_fetcher.py
└── requirements.txt
```

## 処理の流れ

各 `.dig` は次の順に実行されます。

1. `+create_table`：`td_ddl>` で出力先テーブルを作成します（既に存在する場合は何もしません）。
2. `+extract_*`：`py>` で 123FormBuilder API から取得し、pytd で TD に追記（`if_exists='append'`）します。

## 事前準備

1. 取り込み先のデータベースを作成し、`config/params.yml` の `td.database` を設定します。
2. シークレットを設定します（値はファイルに書かないでください）。
   - `formbuilder_username` / `formbuilder_password`：123FormBuilder のログイン情報
   - `td.apikey`：TD の Master API Key（`ACCOUNT_ID/KEY` 形式）。TD operator と `py>` の両方で使用します

   ```
   tdx wf secrets set <project> formbuilder_username=<値> formbuilder_password=<値> td.apikey=<値>
   ```

3. `py>` の実行イメージは `treasuredata/customscript-python:3.12.11-td4` を使用します。

## 実行方法

```
cd td_123formbuilder_import
tdx wf push
```

設定を変える場合は `config/params.yml` を編集してください（`tdx wf push` 時の `-p` 上書きは使いません）。スケジュールは各 `.dig` でコメントアウトしているため、現状は手動実行です。

## 出力テーブル

| テーブル | 内容 | 備考 |
|---|---|---|
| `formbuilder_forms` | フォーム情報・項目 | 実行のたびに追記 |
| `formbuilder_groups` | グループ情報・配下フォーム | 同上 |
| `formbuilder_users` | マスター・サブユーザー情報 | 同上 |
| `formbuilder_submissions` | フォーム投稿 | 同上（現状は全件取得のため重複します） |

## 既知の課題

2026-11 時点の確認で見つかった課題です。仕様の根拠は 123FormBuilder API v2 の Swagger（`swagger-4.json`、2024/01 公開版）です。

1. **認証の渡し方が仕様と異なります。** 仕様では `JWT` をクエリ（GET）またはフォーム（POST）で渡し、ログインは `POST /token?username=&password=` です。現コードは `Authorization: Bearer` ヘッダと JSON body を使っています。
2. **仕様にない API を呼んでいます。** `GET /user` と `GET /users/{id}` は仕様に定義がありません（ユーザー一覧は `GET /users`）。
3. **投稿の回答データが展開されていません。** Submission の `content` は「全フィールドを含む JSON 文字列」ですが、現コードでは文字列のまま格納されます。
4. **投稿が毎回全件 append されます。** `formbuilder_submissions` は日次で重複が積み上がります。`start_submission_id` / `start_date` で増分取得できます。
5. **`extracted_at` は常に NULL です。** TD が自動で埋めるものではないため、取得時刻は実行側で設定する必要があります。
6. **`time` 列を設定していません。** pytd の `load_table_from_dataframe` は `time`（UNIX 秒）を自前で用意する必要があります。
7. **エラーを握りつぶすことがあります。** フォーム単位の取得失敗は読み飛ばし、TD への書き込み失敗は stdout に出して成功扱いになります。
8. **依存パッケージの導入が不足しています。** `requirements.txt` に `pandas` がなく、Custom Script イメージは `requirements.txt` を自動インストールしません。実行時の `pip install` が必要です。
9. **`_error` のメール通知は未実装です。** 現状は `echo>` のみです。
10. **シークレット名の表記が揺れています。** 旧 README は `td_apikey` と記載していましたが、コードは `td.apikey` を参照します。本 README は `td.apikey` に統一しています。
