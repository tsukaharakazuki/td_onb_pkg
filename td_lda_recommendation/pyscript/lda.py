import os, sys
os.system(f"{sys.executable} -m pip install --upgrade pytd==1.3.0")
apikey = os.environ['TD_API_KEY']
endpoint = 'https://' + os.environ['TD_ENDPOINT']
database = os.environ['DATABASE']
session_unixtime = int(os.environ['SESSION_UNIXTIME'])

import pytd
client = pytd.Client(apikey=apikey, endpoint=endpoint, database=database)

def get_train_df(table, uid_col='uid', feature_col='features'):
  import json
  import pandas as pd
  res = client.query(f'select uid, features from {table} where time = {session_unixtime}')
  df = pd.DataFrame(**res)
  df[feature_col] = df[feature_col].map(lambda x:json.loads(x))
  return df

def build_predict(df, n_components, uid_col='uid', feature_col='features'):
  import numpy as np
  import pandas as pd
  from sklearn.feature_extraction import DictVectorizer
  from sklearn.decomposition import LatentDirichletAllocation

  # init
  dv = DictVectorizer()
  lda = LatentDirichletAllocation(n_components=n_components)

  # fit
  sparse_features = dv.fit_transform(df[feature_col])
  result = lda.fit_transform(sparse_features)
  pred = pd.DataFrame({uid_col:df[uid_col], 'cluster':np.argmax(result, axis=1)})

  # Weight
  weights = pd.DataFrame(lda.components_, index=list(range(n_components)), columns=dv.get_feature_names()).T.unstack().reset_index()
  weights.columns = ['n_cluster', 'word', 'weight']

  return pred, weights

def main(n_cluster, source_table, dest_weight_table, dest_pred_table, uid_col='uid', feature_col='features'):
  n_cluster = int(n_cluster)

  df = get_train_df(source_table, uid_col=uid_col, feature_col=feature_col)
  pred, weights = build_predict(df, n_cluster, uid_col=uid_col, feature_col=feature_col)

  # Upload to TD
  client.load_table_from_dataframe(weights.assign(time=session_unixtime), f'{database}.{dest_weight_table}', if_exists='append')
  client.load_table_from_dataframe(pred.assign(time=session_unixtime), f'{database}.{dest_pred_table}', if_exists='append')

if __name__ == '__main__':
  main(10, 'lda_train_ds', 'lda_weights', 'lda_pred')
