#!/usr/bin/python

# !pip install pytd
 
import os, sys
os.system(f"{sys.executable} -m pip install -U pandas==1.2.3")
os.system(f"{sys.executable} -m pip install -U pytd==1.4.3")
import numpy as np
import pandas as pd
import datetime as dt
from dateutil.tz import gettz
from scipy.sparse import dok_matrix
import json 
import gc

import pytd
from pytd import pandas_td as td
from sklearn.ensemble import RandomForestClassifier
 
apikey = os.environ['TD_API_KEY']
endpoint = 'https://' + os.environ['ENDPOINT']
con = td.Client(apikey=apikey, endpoint=endpoint)

def create_sparse_features(query_result, n_features):
  features = dok_matrix((len(query_result['data']), n_features), dtype=np.float32)
  for i,r in enumerate(query_result['data']):
    j = json.loads(r[0])
    for k, v in j.items():
      features[i, int(k)] = v
  return features

def main(database, date, n_split, n_features, timezone):
  n_split = int(n_split)
  n_features = int(n_features)
  client = pytd.Client(apikey=apikey, endpoint=endpoint)
  
  result = client.query(f'''
    select
      features, target
    from
      {database}.train
    where
      is_test = 0
  ''')
  
  target = [r[1] for r in result['data']]
  features = create_sparse_features(result, n_features)

  clf = RandomForestClassifier(n_estimators=100)
  clf.fit(features, target)
  print(target[0], features)

  del target, features;gc.collect()

  for i in range(n_split):
    result = client.query(f'''
      select
        features, uid
      from
        {database}.preprocessed
      where
        nth_group = {i}
    ''')
    features = create_sparse_features(result, n_features)
    pred = clf.predict(features)
    uids = [r[1] for r in result['data']]
    time = int(dt.datetime.strptime(date, '%Y-%m-%d').astimezone(gettz(timezone)).timestamp())
    pred_df = pd.DataFrame({'pred':pred, 'uid':uids}).assign(time=time)
    del pred, uids;gc.collect()
    td.to_td(pred_df, f'{database}.predicted', con=con, if_exists='append', time_col='time', index=False)
    # client.load_table_from_dataframe(pred_df, f'{database}.predicted', writer='spark', if_exists='overwrite')


#if __name__ == '__main__':
#  client, pred = main('{database}', '{date}', 10, 1000)
