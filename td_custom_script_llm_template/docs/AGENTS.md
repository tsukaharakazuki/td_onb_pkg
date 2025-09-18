# TreasureData Custom Script Docment
## TreasureDataのCustomScriptの仕様
- DIGFILE_NAME.dig: Workflowの挙動を制御します
- PYTHON_SCRIPT_NAME.py: pythonの処理をが記述されます
- config/params.yml: 変数設定などをまとめたファイルです

## 処理フロー作成Tips
- sample.dig / sample.pyには、TreasureDataの中のテーブルからデータを取得し、pythonで処理したデータをTreasureDataに出力する、ベージックな処理が記述されています
- 上記を参考に、指示を受けた処理を作成してください

### 参考文献
[リンク集](https://docs.treasuredata.com/display/public/PD/Custom+Scripts)  
[イントロダクション](https://docs.treasuredata.com/display/public/PD/Introduction+to+Custom+Scripts)  
[Workflowへの追加](https://docs.treasuredata.com/display/public/PD/Adding+a+Custom+Python+Script+to+Your+Workflow)  
[構文](https://docs.treasuredata.com/display/public/PD/Workflow+py+Operator+Syntax+Reference#WorkflowpyOperatorSyntaxReference-Syntax)  
[パラメータ引渡し](https://docs.treasuredata.com/display/public/PD/Passing+Parameters+to+Custom+Scripts+used+in+TD+Workflow)  
[エンジニアブログ](https://td-support.hatenablog.com/entry/2020/06/26/171001)  
