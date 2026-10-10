# td_emarsys_export — AI アシスタント向けガイド

このフォルダは Treasure Data → SAP Emarsys 送信ワークフローのテンプレートです。
設定支援（Emarsys 連携の構築、config の作成、テスト・デプロイ）を依頼されたら、
Skill がインストールされていなくても、次の Skill ファイルを読んでその手順に従ってください。

- Skill: `../.claude/skills/td-emarsys-export-builder/SKILL.md`
  （GitHub: https://github.com/tsukaharakazuki/td_onb_pkg/blob/main/.claude/skills/td-emarsys-export-builder/SKILL.md ）
- 詳細設定ドキュメント: `docs/config_common.md` / `docs/config_sftp.md` / `docs/config_webdav.md` / `docs/config_targets.md`

ルール:
- 顧客ごとの設定は新しいフォルダにコピーして行い、このテンプレート自体は書き換えない（`.claude/` と `CLAUDE.md` はコピー不要）。
- パスワード・WebDAV シークレット・API キーをチャットに貼らせない。Secrets はユーザー自身が登録する。
- `tdx wf run` は Emarsys に実データを送信する。必ず `--dry-run` で内容を説明し、明示的な承認を得てから実行する。
