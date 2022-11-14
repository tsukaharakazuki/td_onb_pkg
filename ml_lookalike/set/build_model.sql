select 
 target, 
 feature,
 argmin_kld(weight, covar) as weight
from (
  select 
    train_multiclass_scw(features, target) as (target, feature, weight, covar)
  from (
    select
      features
      ,target
    from 
      train_${set[params].name}
    where
     is_test = 0
    cluster by
      rand()
    ) t0
 ) t1
group by
  1,2
