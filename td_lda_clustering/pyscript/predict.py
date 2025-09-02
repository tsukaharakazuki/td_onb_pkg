import os, sys
os.system(f"{sys.executable} -m pip install --upgrade pytd==1.3.0")
apikey = os.environ['TD_API_KEY']
endpoint = 'https://' + os.environ['TD_ENDPOINT']
database = os.environ['DATABASE']
session_unixtime = int(os.environ['SESSION_UNIXTIME'])

import pytd
import json
import pickle
import base64
import pandas as pd
import numpy as np
client = pytd.Client(apikey=apikey, endpoint=endpoint, database=database)

def get_prediction_df(table, uid_col='uid', feature_col='features'):
    query = f'select uid, features from {table} where time = {session_unixtime}'
    print(f"Executing query: {query}")
    res = client.query(query)
    df = pd.DataFrame(**res)
    print(f"Retrieved {len(df)} records from {table}")
    
    if df.empty:
        print(f"WARNING: No data found in {table} for time = {session_unixtime}")
        return df
    
    df[feature_col] = df[feature_col].map(lambda x:json.loads(x) if x else {})
    return df

def get_latest_model(model_table):
    # Get the latest model time
    query = f"""
    SELECT MAX(time) as latest_time 
    FROM {model_table}
    """
    res = client.query(query)
    df = pd.DataFrame(**res)
    
    if df.empty or df['latest_time'].iloc[0] is None:
        raise ValueError(f"No model found in {model_table}")
    
    latest_time = df['latest_time'].iloc[0]
    
    # Get all chunks for the latest model
    query = f"""
    SELECT chunk_id, model_data, n_cluster, total_chunks
    FROM {model_table} 
    WHERE time = {latest_time}
    ORDER BY chunk_id
    """
    res = client.query(query)
    df = pd.DataFrame(**res)
    
    if df.empty:
        raise ValueError(f"No model chunks found in {model_table}")
    
    # Verify all chunks are present
    expected_chunks = df['total_chunks'].iloc[0]
    if len(df) != expected_chunks:
        raise ValueError(f"Missing model chunks: found {len(df)}, expected {expected_chunks}")
    
    # Reconstruct model from chunks
    model_str = ''.join(df['model_data'].tolist())
    model_bytes = base64.b64decode(model_str.encode('utf-8'))
    model_data = pickle.loads(model_bytes)
    
    print(f"Model reconstructed from {expected_chunks} chunks")
    
    return model_data

def predict_with_saved_model(df, model_data, uid_col='uid', feature_col='features'):
    # Extract model components
    lda = model_data['lda']
    dv = model_data['dv']
    
    # Transform features and predict
    sparse_features = dv.transform(df[feature_col])
    result = lda.transform(sparse_features)
    
    # Get cluster assignments
    pred = pd.DataFrame({
        uid_col: df[uid_col], 
        'cluster': np.argmax(result, axis=1)
    })
    
    return pred

def main(source_table, model_table, dest_pred_table, uid_col='uid', feature_col='features'):
    # Get prediction data
    df = get_prediction_df(source_table, uid_col=uid_col, feature_col=feature_col)
    
    # Check if data is available
    if df.empty:
        print(f"ERROR: No prediction data available in {source_table}")
        print("Please ensure that the prediction data is properly created before running this script")
        raise ValueError(f"No prediction data found in {source_table}")
    
    # Load saved model
    print(f"Loading model from {model_table}")
    model_data = get_latest_model(model_table)
    print(f"Model loaded successfully with {model_data['n_components']} components")
    
    # Make predictions
    pred = predict_with_saved_model(df, model_data, uid_col=uid_col, feature_col=feature_col)
    
    # Upload predictions to TreasureData
    client.load_table_from_dataframe(
        pred.assign(time=session_unixtime), 
        f'{database}.{dest_pred_table}', 
        if_exists='append'
    )
    
    print(f"Predictions completed for {len(pred)} records using model with {model_data['n_components']} clusters")

if __name__ == '__main__':
    main('lda_train_ds', 'lda_model', 'lda_pred')