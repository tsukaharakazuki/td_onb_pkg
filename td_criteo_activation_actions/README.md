# このWorkflowについて
このWorkflowは、AudienceStudioのActivation機能における `Activation Actions` で、Criteoにセグメントを送信する処理です。  
Criteoの初回セグメント作成（セグメントIDの取得）、過去に送信したIDを削除して再送するリプレイス送信が通常のActivationではできないため、本処理を利用します。

# 初回のセグメント作成
`td_criteo_create_segment`を指定します。  
Activationの作成の際、`id`（本来はセグメントIDが入る部分）には、なんでも良いので文字を入力してください。（意図がなければ`新規作成`など入力してください。）

# リプレイス
`td_criteo_replace`を指定します。  
こちらの処理は、すでにActivationされたIDを保管しておき、前回送信したセグメントを削除した上で、新規のセグメントを送ることでリプレイスの挙動を実現します。

# Activation Setting
## Output Mapping
![Image](https://github.com/tsukaharakazuki/td_onb_pkg/blob/main/img/criteo_activation_output.png)
