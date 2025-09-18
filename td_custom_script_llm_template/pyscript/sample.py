import os
import sys
import pandas as pd
os.system(f"{sys.executable} -m pip install -U pytd==1.3.0")
import pytd

# 環境変数から設定を取得
apikey = os.environ['TD_API_KEY']
endpoint = 'https://' + os.environ['ENDPOINT']
session_unixtime = int(os.environ['SESSION_UNIXTIME'])

def main(database, table, dist_table, timezone):
    """
    指定されたテーブルから100件のレコードを取得し、出力テーブルに保存する
    """

    # TreasureDataクライアントを初期化
    client = pytd.Client(apikey=apikey, endpoint=endpoint)

    # SQLクエリを実行（100件制限）
    query = f"""
    SELECT *
    FROM {database}.{table}
    LIMIT 100
    """

    print(f"Executing query: {query}")

    # クエリを実行
    result = client.query(query)

    # 結果をDataFrameに変換
    if isinstance(result, dict) and 'data' in result and 'columns' in result:
        # pytdが返すdict形式 {'data': [...], 'columns': [...]} を変換
        df = pd.DataFrame(result['data'], columns=result['columns'])
    else:
        # その他の形式（既にDataFrameの場合など）
        df = result

    print(f"Retrieved {len(df)} records from {database}.{table}")

    # 結果を出力テーブルに保存
    client.load_table_from_dataframe(
        df,
        f"{database}.{dist_table}",
        if_exists='overwrite'
    )

    print(f"Successfully saved {len(df)} records to {database}.{dist_table}")

if __name__ == "__main__":
    main()