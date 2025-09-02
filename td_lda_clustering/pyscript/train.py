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
client = pytd.Client(apikey=apikey, endpoint=endpoint, database=database)

def get_train_df(table, uid_col='uid', feature_col='features'):
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

def train_and_save(df, n_components, uid_col='uid', feature_col='features'):
    import numpy as np
    from sklearn.feature_extraction import DictVectorizer
    from sklearn.decomposition import LatentDirichletAllocation
    
    # Initialize
    dv = DictVectorizer()
    lda = LatentDirichletAllocation(n_components=n_components)
    
    # Fit
    sparse_features = dv.fit_transform(df[feature_col])
    lda.fit(sparse_features)
    
    # Extract weights
    weights = pd.DataFrame(lda.components_, index=list(range(n_components)), columns=dv.get_feature_names()).T.unstack().reset_index()
    weights.columns = ['n_cluster', 'word', 'weight']
    
    # Serialize model and vectorizer
    model_data = {
        'lda': lda,
        'dv': dv,
        'n_components': n_components
    }
    
    # Convert to base64 string for storage
    model_bytes = pickle.dumps(model_data, protocol=pickle.HIGHEST_PROTOCOL)
    model_str = base64.b64encode(model_bytes).decode('utf-8')
    
    # Split model into chunks (100KB per chunk to be safe)
    chunk_size = 100000  # 100KB chunks
    model_chunks = [model_str[i:i+chunk_size] for i in range(0, len(model_str), chunk_size)]
    
    print(f"Model size: {len(model_str)} chars, split into {len(model_chunks)} chunks")
    
    return weights, model_chunks

def main(n_cluster, source_table, dest_weight_table, dest_model_table, uid_col='uid', feature_col='features'):
    n_cluster = int(n_cluster)
    
    # Get training data
    df = get_train_df(source_table, uid_col=uid_col, feature_col=feature_col)
    
    # Check if data is available
    if df.empty:
        print(f"ERROR: No training data available in {source_table}")
        print("Please ensure that the training data is properly created before running this script")
        raise ValueError(f"No training data found in {source_table}")
    
    # Train model and get weights
    weights, model_chunks = train_and_save(df, n_cluster, uid_col=uid_col, feature_col=feature_col)
    
    # Save weights to TreasureData
    client.load_table_from_dataframe(
        weights.assign(time=session_unixtime), 
        f'{database}.{dest_weight_table}', 
        if_exists='append'
    )
    
    # Save model chunks to TreasureData
    model_records = []
    for i, chunk in enumerate(model_chunks):
        model_records.append({
            'time': session_unixtime,
            'chunk_id': i,
            'total_chunks': len(model_chunks),
            'model_data': chunk,
            'n_cluster': n_cluster
        })
    
    model_df = pd.DataFrame(model_records)
    client.load_table_from_dataframe(
        model_df, 
        f'{database}.{dest_model_table}', 
        if_exists='append'
    )
    
    print(f"Model trained and saved in {len(model_chunks)} chunks. Clusters: {n_cluster}")

if __name__ == '__main__':
    main(10, 'lda_train_ds', 'lda_weights', 'lda_model')