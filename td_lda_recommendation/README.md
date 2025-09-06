# TD LDA レコメンデーション

LDA（Latent Dirichlet Allocation）を用いて行動データ、購買データなどのトランザクションデータからクラスタリング処理を行い、レコメンデーション結果を生成するDigdagワークフローです。

## 概要

このワークフローはTreasure Data上で以下の処理を実行します：

1. **データ前処理**: 指定された期間のトランザクションログから学習用データセットを作成
2. **LDAモデル学習**: scikit-learnを使用してLDAモデルを構築
3. **レコメンデーション生成**: 各ユーザーに対して類似クラスターからアイテムを推薦

## ファイル構成

```
td_lda_recommendation/
├── README.md                    # このファイル
├── td_lda_recommend.dig        # メインのDigdagワークフロー
├── config/
│   └── params.yml              # パラメータ設定ファイル
├── pyscript/
│   └── lda.py                  # LDAモデルの学習・予測処理
└── sql/
    ├── main_param.sql          # メインパラメータデータ抽出
    ├── sub_param.sql           # サブパラメータデータ抽出
    ├── create_training_dataset.sql  # 学習データセット作成
    ├── create_recommend_data.sql    # レコメンデーションデータ生成
    └── except_purchased_item.sql    # 購入済みアイテム除外処理
```

## セットアップ

### 1. パラメータ設定

`config/params.yml`を編集して以下を設定：

- **データソース設定**: `main`、`sub`セクションでソーステーブルとカラムを指定
- **LDAパラメータ**: クラスター数（`n_cluster`）、学習期間（`interval`）等
- **ユーザーデータ**: レコメンデーション対象ユーザーのテーブル情報

### 2. 必要なテーブル

以下のテーブルが利用可能である必要があります：

- ユーザー行動ログテーブル（webログ、購買履歴等）
- ユーザーマスターテーブル

## 実行方法

```bash
# ワークフローの実行
digdag run td_lda_recommend.dig
```

## 生成されるテーブル

| テーブル名 | 内容 |
|-----------|------|
| `train_ds_[name]` | 学習用データセット |
| `weights_[name]` | LDAモデルの重み |
| `pred_[name]` | ユーザークラスター予測結果 |
| `td_lda_recommend_[name]` | レコメンデーション結果 |
| `history_[name]` | パラメータ履歴 |

## パラメータ詳細

### 主要パラメータ

- `n_cluster`: LDAのトピック数（クラスター数）
- `interval`: 学習データに使用するログの期間（日数）
- `at_least`: 学習に必要な最低ログ数
- `item_num`: 推薦アイテム数

### データソース設定

- `main`: 主要な行動データ（例：閲覧アイテム）
- `sub`: 補助的な行動データ（例：ソース情報）

## 注意事項

- Digdag環境でPython 3.9が利用可能である必要があります
- Treasure DataのAPIキーが適切に設定されている必要があります
- 十分なデータ量がないと学習が適切に行われない可能性があります