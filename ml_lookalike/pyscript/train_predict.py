#!/usr/bin/python

# !pip install pytd
 
import os, sys
import numpy as np
import pandas as pd
import datetime as dt
from dateutil.tz import gettz
from scipy.sparse import dok_matrix
import json 
import gc

os.system(f"{sys.executable} -m pip install -U pytd==1.3.0")
import pytd
from pytd import pandas_td as td
from sklearn.ensemble import RandomForestClassifier

apikey = os.environ['TD_API_KEY']
endpoint = 'https://' + os.environ['ENDPOINT']
session_unixtime = int(os.environ['SESSION_UNIXTIME'])

def create_sparse_features(query_result, n_features):
  features = dok_matrix((len(query_result['data']), n_features), dtype=np.float32)
  for i,r in enumerate(query_result['data']):
    j = json.loads(r[0])
    for k, v in j.items():
      features[i, int(k)] = v
  return features

def main(database, n_split, n_features, timezone, train, predicted, preprocessed):
  n_split = int(n_split)
  n_features = int(n_features)
  client = pytd.Client(apikey=apikey, endpoint=endpoint)
  
  result = client.query(f'''
    select
      features, target
    from
      {database}.{train}
    where
      is_test = 0
  ''')
  
  target = [r[1] for r in result['data']]
  features = create_sparse_features(result, n_features)

  clf = RandomForestClassifier(n_estimators=100, max_depth=10)
  clf.fit(features, target)

  del target, features;gc.collect()

  for i in range(n_split):
    result = client.query(f'''
      select
        features, uid
      from
        {database}.{preprocessed}
      where
        nth_group = {i}
    ''')
    features = create_sparse_features(result, n_features)
    pred = [p[1] for p in clf.predict_proba(features)]
    uids = [r[1] for r in result['data']]
    pred_df = pd.DataFrame({'pred':pred, 'uid':uids}).assign(time=session_unixtime)
    del pred, uids;gc.collect()
    print(pred_df)
    client.load_table_from_dataframe(pred_df, f'{database}.{predicted}', if_exists='append')

if __name__ == '__main__':
  client, pred = main('ml_data', '2021-04-01', 10, 1000)
