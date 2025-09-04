# LINE Audience Delete Workflow for TreasureData

TreasureDataからLINE Messaging APIのオーディエンス（セグメント）を削除するためのDigdagワークフローです。

## 機能

- LINE Messaging APIのオーディエンスグループを指定して削除
- 複数のオーディエンスIDを一括削除
- ページネーション対応により全オーディエンスの取得が可能（147件以上対応）
- 削除結果のログ記録（TreasureDataへの保存）
- エラーハンドリングと詳細なログ出力

## 必要な設定

### TreasureData シークレット

以下のシークレットを事前に設定してください：

```
td secret:set line.channel_access_token <YOUR_LINE_CHANNEL_ACCESS_TOKEN>
td secret:set td.apikey <YOUR_TD_API_KEY>
```

### 環境変数

- `LINE_CHANNEL_ACCESS_TOKEN`: LINE Messaging APIのチャンネルアクセストークン
- `TD_ENDPOINT`: TreasureDataのエンドポイント（デフォルト: api.treasuredata.com）
- `TD_API_KEY`: TreasureDataのAPIキー
- `AUDIENCE_IDS`: 削除対象のオーディエンスID
- `DELETION_TYPE`: 削除タイプ（"audience" または "audienceGroup"、デフォルト: "audienceGroup"）

## 使い方

### 1. 単一のオーディエンスを削除

```yaml
_export:
  audience_ids: "1111111111111"
```

### 2. 複数のオーディエンスを削除

```yaml
_export:
  audience_ids: "1111111111111,1111111111112,1111111111113"
```

### 3. ワークフローの実行

```bash
td wf push td_line_audience_delete
td wf start td_line_audience_delete td_line_audience_delete --session now
```

## ワークフローの構成

### td_line_audience_delete.dig

メインのDigdagワークフローファイル。以下の設定が含まれています：

- タイムゾーン設定（Asia/Tokyo）
- TreasureDataのデータベース設定
- 削除対象のオーディエンスID
- Pythonスクリプトの実行設定

### line_audience_deleter.py

LINE APIとの通信を行うPythonスクリプト。以下の機能を提供：

- **LINEAudienceDeleterクラス**
  - `get_audience_groups()`: 全オーディエンスグループの取得（ページネーション対応）
  - `delete_audience_group()`: オーディエンスグループの削除
  - `delete_audience()`: 個別オーディエンスの削除
  - `get_audience_group_status()`: ステータス確認
  - `delete_multiple_audiences()`: 複数オーディエンスの一括削除

- **TreasureDataIntegrationクラス**
  - `log_deletion_results()`: 削除結果のTreasureDataへの記録

## ログ出力

ワークフローは以下の情報をログに出力します：

1. **削除前のオーディエンス一覧**
   - 全オーディエンスのID、名前、ステータス

2. **削除処理**
   - 各削除対象の処理状況
   - HTTPステータスコード（200, 202, 204は成功）

3. **削除結果のサマリー**
   - 成功件数
   - 失敗件数
   - 見つからなかった件数

4. **削除後のオーディエンス一覧**
   - 削除後の全オーディエンスのID、名前、ステータス

## 注意事項

- LINE APIのレート制限を考慮し、各API呼び出し間に適切な待機時間を設定
- HTTP 202（Accepted）は削除成功として扱われます
- 削除結果はTreasureDataの`td_sandbox.line_audience_deletion_log`テーブルに記録されます（テーブルが存在する場合）

## トラブルシューティング

### オーディエンスが20件しか取得できない

→ ページネーション対応済みのため、現在は全件取得可能です

### 削除が失敗と表示される

→ HTTP 202ステータスコードも成功として扱うよう修正済みです

### TreasureDataへのログ記録でエラー

→ データベース名を`td_sandbox`に設定済みです。テーブルが存在しない場合は事前に作成してください

## 依存パッケージ

- requests
- pytd
- pandas

## ライセンス

内部利用のみ
