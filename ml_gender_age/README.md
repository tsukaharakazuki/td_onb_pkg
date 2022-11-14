# はじめに
  
このWorkflowは、１０歳刻みで年齢と性別を機械学習にて推計するWorkflowです。
  
# モデルの変更
  
1. LGBMClassifier

17行目. 
from sklearn.ensemble import RandomForestClassifier
-> from lightgbm import LGBMClassifier 
  
48行目. 
clf = LGBMClassifier(n_estimators=100, max_depth=10)
