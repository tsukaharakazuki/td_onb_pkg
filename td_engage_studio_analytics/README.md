# TD Engage Studio Analytics

Treasure Data Engage Studio用のメール配信分析パイプライン

## 概要

このプロジェクトは、Treasure Data Engageから送信されるメールイベントデータを処理・分析するためのDigdagワークフローです。メールの送信、配信、開封、クリック、バウンスなどのイベントを集計し、分析用のテーブルを生成します。

## アーキテクチャ

```
Engage Event Data → Organize → Aggregate → Analytics (Total/Daily)
```

## データフロー

1. **データ整理** (`organize_engage_event_data`)
   - Engageイベントテーブルから必要なフィールドを抽出
   - 送信者メールアドレスの正規化
   - イベントタイムスタンプの統一

2. **データ集約** (`agg_engage_event_data`)
   - メッセージIDと受信者ごとにイベントを集約
   - 各イベント（送信、配信、開封、クリック、バウンス）のタイムスタンプを整理

3. **分析データ生成**
   - **Total分析** (`engage_studio_analytics_total`): キャンペーン全体の統計
   - **Daily分析** (`engage_studio_analytics_daily`): 日別イベント統計

## 生成される指標

### Total分析
- 送信数・配信数・開封数・クリック数・バウンス数
- 開封率・クリック率・クリック to オープン率

### Daily分析
- 日別のイベント発生数
- イベントタイプ別の統計

## 設定

### 必要な設定項目

- `engage_databse`: Engageデータベース名
- `engage_event_table`: イベントテーブル名
- `td.database`: 出力先データベース

### 初回実行設定

`at_firsttime`フラグでテーブルの初期化方法を制御：
- `true`: 新しいテーブルを作成
- `false`: 既存テーブルのデータを削除

## 実行方法

```bash
# 初回実行（テーブル作成）
digdag run td_engage_studio_analytics.dig

# 通常実行（データ更新）
digdag run td_engage_studio_analytics.dig -p at_firsttime=false
```

## テーブル構造

### organize_engage_event_data
- イベントの基本情報とタイムスタンプ

### agg_engage_event_data  
- メッセージ・受信者単位で集約されたイベントデータ

### engage_studio_analytics_total
- キャンペーン全体の配信実績サマリー

### engage_studio_analytics_daily
- 日別のイベント発生統計

## エラーハンドリング

エラー発生時は `config/error.dig` で定義された通知が実行されます。

## タイムゾーン

Asia/Tokyo (JST) を使用して時刻を処理します。