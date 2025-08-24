# TD Activation Actions Workflow

このワークフローは、Treasure Dataを使用してアクティベーションアクションデータから重複を除いた最初のレコードを抽出するDigdagワークフローです。

## 概要

このワークフローは、指定されたキー列（デフォルト：email）でパーティションを作成し、時間順で最初に発生したレコードのみを抽出します。マーケティングオートメーションやユーザー行動分析において、初回アクション（初回登録、初回購入など）を特定する際に有用です。

## ファイル構成

```
td_activation_actions/
├── README.md
├── td_distinct_email.dig          # メインワークフローファイル
└── queries/
    └── distinct_email.sql         # SQLクエリファイル
```

## ワークフロー詳細

### td_distinct_email.dig

メインのワークフロー定義ファイルです：

- **_export**: 設定変数のエクスポート
  - `database`: 対象データベース名（`${activation_actions_db}`）
  - `key_column`: パーティションキーとなる列名（デフォルト：email）

- **+distinct_email**: メインタスク
  - SQLクエリを実行し、結果を指定された接続先にエクスポート

### queries/distinct_email.sql

重複除去を行うSQLクエリ：

1. `ROW_NUMBER()`を使用してパーティション内で時間順にランク付け
2. 各グループの最初のレコード（`num = 1`）のみを選択

## 必要な環境変数

ワークフローを実行する前に、以下の環境変数を設定してください：

| 変数名 | 説明 | 例 |
|--------|------|-----|
| `activation_actions_db` | 対象データベース名 | `my_database` |
| `activation_actions_table` | 対象テーブル名 | `user_actions` |
| `result_connection_name` | 結果出力先の接続名 | `output_connection` |
| `result_connection_settings` | 結果出力の設定 | `{"type": "s3", "bucket": "my-bucket"}` |
| `key_colmun` | パーティションキー列名（デフォルト：email） | `email` |

## 使用方法

1. 必要な環境変数を設定
2. Digdagでワークフローを実行：

```bash
digdag run td_distinct_email.dig
```

## クエリロジック

このワークフローのSQLクエリは以下の処理を行います：

1. **パーティション作成**: 指定されたキー列で重複レコードをグループ化
2. **時間順ソート**: 各グループ内で`time`列の昇順でソート
3. **最初のレコード選択**: `ROW_NUMBER() = 1`の条件で各グループの最初のレコードのみ抽出

## 出力

- 重複を除いた最初のアクティベーションアクションレコード
- 指定された結果接続先に出力

## 注意事項

- `key_colmun`変数名にタイポがありますが、既存の実装に合わせて維持しています
- 時間列として`time`を使用していることを前提としています
- 大量データの場合は、適切なパーティション設定を検討してください