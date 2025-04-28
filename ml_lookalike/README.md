# TD Machine Learning Lookalike Model

このWorkflowは、目的変数として設定した条件（例：商品購入、来店）に合わせて、WebログやAppログ、その他行動ログから機械学習でスコアリングするWorkflowです。Treasure Dataのプラットフォーム上で動作し、簡単な設定だけで高度な機械学習モデルを実行できます。

## 概要

- **モデル**: RandomForestClassifier（scikit-learn）
- **目的**: 特定の行動（コンバージョン）をとるユーザーと類似したユーザーをスコアリング
- **特徴**: 設定ファイル（`config/params.yml`）の編集だけで機械学習モデルが実行可能

## 運用方法

### モード選択

システムは2つの運用モードをサポートしています：

1. **SETモード**: 事前定義されたSQL条件に基づいてターゲットユーザーを定義
2. **CDPモード**: Customer Data Platformのセグメントに基づいてターゲットユーザーを定義

### 実行フロー

1. **特徴量抽出**:
   - 各種データソースから特徴量を抽出
   - 複数のデータソース（WebログとAppログなど）を組み合わせ可能

2. **ターゲット作成**:
   - 指定条件に基づき、ポジティブ・ネガティブサンプルを作成

3. **モデルトレーニング**:
   - RandomForestClassifierによるモデル学習
   - トレーニング/テストデータの分割（デフォルト: 80/20）

4. **予測と評価**:
   - 全ユーザーに対するスコア予測
   - AUCメトリクスによるモデル評価

## 特徴量タイプ

システムは以下の特徴量タイプをサポートしています：

1. **属性特徴量** (`feature_attribute`):
   - 会員情報など1ユーザー1レコードしか持っていないデータ
   - 例：性別、年齢層など

2. **カテゴリカル特徴量** (`feature_categorical`):
   - 閲覧コンテンツ、リファラなどIDが複数の値を持つカラムの割合計算
   - 例：閲覧ページ、参照元ドメイン、アクセス時間帯など

3. **最大値特徴量** (`feature_max_by_n`):
   - 都道府県、OSなどIDが複数の値を持つカラムの最大の値
   - 例：最も頻繁に使用するOS、最も多いアクセス都道府県など

4. **数量特徴量** (`feature_quantitative`):
   - 課金額カラムなど数値を合計した値
   - 例：総課金額、総購入回数など

5. **配列カテゴリカル特徴量** (`feature_categorical_array`):
   - 配列カラム内のデータを展開して割合計算
   - 例：購入商品SKUなど

6. **配列カウント特徴量** (`feature_categorical_array_cnt`):
   - 配列カラム内のデータを展開して出現回数計算
   - 例：注文情報など

## 設定方法

### 基本設定 (`config/params.yml`)

```yaml
---
target_type: cdp #cdp or set

# SETモード設定
set:
  ec_conv:  # 任意の名前（複数定義可能）
    firsttime: true  # 初回実行時：true、定期実行時：false
    name: ec_conv  # 結果テーブル名の一部になります
    output_db: td_sandbox  # 結果出力先データベース
    
    # 目的変数設定
    target_db: target_db  # 教師データを作成するDatabase
    target_tbl: target_tbl  # 教師データを作成するTable
    target_id: td_ms_id  # KeyとなるID（cookie、MobileID、UserIDなど）
    target_time_range: TD_INTERVAL(time, '-28d', 'JST')  # 教師データ期間
    target_positive:  # 正例の条件
      condition:
        - td_path = '/ordercomplete'  # 購入完了ページ訪問など

# 説明変数設定
ftr:
  feature:
    feature_time_range: TD_INTERVAL(time, '-60d', 'JST')
    # 各種特徴量定義...
```

### 複数モデルの設定

`set:`セクション内に複数の設定を追加することで、複数のモデルを同時に実行できます。以下は例です：

```yaml
set:
  ec_conv:  # ECサイト購入者予測
    # 設定...
  
  store_visit:  # 店舗来店予測
    firsttime: true
    name: store_visit
    output_db: td_sandbox
    target_db: target_db
    target_tbl: store_visit_tbl
    target_id: td_ms_id
    target_time_range: TD_INTERVAL(time, '-28d', 'JST')
    target_positive:
      condition:
        - event_type = 'store_visit'
```

## 結果確認

モデル実行後、以下のテーブルが生成されます：

1. **予測結果**: `predicted_{モデル名}`
   - 各ユーザーのスコア（確率値）

2. **モデル評価**: `result_summary_{モデル名}`
   - トレーニングデータとテストデータそれぞれのAUC値

## 運用スケジュール

定期実行するには、`td_ml_lookalike.dig`のスケジュール設定を有効にします：

```
schedule:
  daily>: 02:50:00
```

## API連携

予測結果をAPIで取得する場合は、以下のクエリを使用します：

```sql
SELECT 
  uid, 
  pred 
FROM 
  {output_db}.predicted_{モデル名} 
WHERE 
  time = (SELECT MAX(time) FROM {output_db}.predicted_{モデル名})
ORDER BY 
  pred DESC
```

## トラブルシューティング

- **AUCが低い場合**: 特徴量の期間や種類を見直してください
- **予測結果がない**: IDの一貫性を確認してください
- **実行エラー**: ログを確認し、テーブル名やカラム名が正しいか確認してください

## 高度な設定

より高度な設定を行う場合は以下のファイルを編集します：

- `pyscript/train_predict.py`: モデルのパラメータ調整やアルゴリズム変更
- `td_ml_lookalike.dig`: ワークフローの実行順序や依存関係の調整

## 参考ドキュメント

詳細なドキュメントは以下を参照してください：
https://docs.google.com/presentation/d/1hCl3UBvcZ56MxQ2bERAh-kndFtIU4vfhFLJga8fk0TA/
