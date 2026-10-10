---
name: td-emarsys-export-builder
description: Use when the user wants to send Treasure Data data to SAP Emarsys (Engagement Cloud) — contacts, opt-out, or sales_items (Smart Insight) — via the td_emarsys_export workflow template (tsukaharakazuki/td_onb_pkg/td_emarsys_export). Fetches the template from GitHub, interviews the user, chooses the send method (TD SFTP connector or Custom Script Python upload to Emarsys WebDAV, or both), defines multiple send datasets in targets for for_each, verifies source tables and SELECT columns with read-only tdx queries, checks the SFTP Authentication exists, writes config/common.yml / sftp.yml / webdav.yml, and guides secrets, push and a dry-run-first test run. Trigger on 「Emarsys連携」「Emarsysにデータ送信」「Emarsysへエクスポート」「td_emarsys_export」「EmarsysのSFTP」「Emarsys WebDAV」「webdav.emarsys.net」「連絡先インポート自動化」「sales_itemsを送る」「SAP Engagement Cloud連携」, Emarsys export, Emarsys auto-import, Emarsys contact import workflow.
---

# TD → Emarsys Export Builder

Configure the `td_emarsys_export` Treasure Workflow that sends TD query results to SAP Emarsys auto-import as UTF-8 CSV. All customer-specific settings live in `config/*.yml`; the dig and SQL are generic. Your job is to interview the user, fill the configs correctly, verify them against real tables, and hand over a safe deploy path.

- Template: https://github.com/tsukaharakazuki/td_onb_pkg/tree/main/td_emarsys_export
- Detailed config docs — in the template's `docs/` (fallback: `references/` next to this SKILL.md, if present):
  - `config_common.md` — send_method, td_api_endpoint
  - `config_sftp.md` — SFTP connector settings, fixed result_settings
  - `config_webdav.md` — WebDAV settings, secrets, Python script spec
  - `config_targets.md` — targets fields, contacts / sales_items examples

Read the relevant doc before editing a config — they hold the parameter tables and Emarsys file rules. If the template `docs/` and `references/` differ, trust the template.

## How the template works (keep this model in mind)

- `common.yml` → `send_method.sftp` / `send_method.webdav` (independent booleans; both true = send both).
- `+sftp` scope includes `config/sftp.yml`, `+webdav` scope includes `config/webdav.yml`. Each file defines its own `targets:` map, and each scope runs `for_each>: target: ${Object.keys(targets)}`. Same variable name, separate scopes → one shared SQL `query/export_select.sql` reading `${targets[target].columns / source_db / source_table / where}`.
- SFTP: `td>` + `result_connection` writes `{base_dir}/{file_prefix}_{session_date_compact}.csv`.
- WebDAV: `td>` (job result only) → `py>: scripts.webdav_upload.main` with `${td.last_job_id}` → streams result to CSV → HTTP PUT to `{base_url}/{directory}/{file_prefix}_{yyyyMMdd}.csv`.
- Switching behavior is done by editing config and pushing. Don't suggest `-p` overrides — they don't override `_export` values on TD.

## Step 1. Locate or fetch the template

- **Already inside the template** (the working directory or a parent contains `td_emarsys_export.dig` — e.g. the user opened the cloned repo): use that folder as the template source.
- **Otherwise** clone it:

```bash
git clone --depth 1 https://github.com/tsukaharakazuki/td_onb_pkg.git .td_onb_pkg_src
```

If git is unavailable, fetch files from `https://raw.githubusercontent.com/tsukaharakazuki/td_onb_pkg/main/td_emarsys_export/<path>`.

Create the customer project as a new folder (don't overwrite an existing one; e.g. `emarsys_export_<client>`), so the template stays clean for the next customer. Leave out `.claude/` and `CLAUDE.md` — they are for the AI assistant, not for TD Workflow:

```bash
rsync -a --exclude .claude --exclude CLAUDE.md <template_dir>/ ./<project_name>/
```

Read `README.md`, `td_emarsys_export.dig`, and the three configs first so you follow the template's current behavior.

## Step 2. Interview (ask together, in one message)

1. Send method: SFTP / WebDAV / both. (Emarsys treats WebDAV as legacy and recommends SFTP or API for new integrations — mention this if they choose WebDAV.)
2. tdx profile and region (sets `td_api_endpoint` for WebDAV).
3. Datasets to send — for each: Emarsys data type (contacts / opt-in / sales_items / other), source DB.table, columns and their Emarsys field names, full or delta (which time column), file name pattern configured in Emarsys auto-import.
4. SFTP: TD Authentication name, home-relative or absolute path, target directory.
5. WebDAV: directory shown in Emarsys 管理 > セキュリティ設定 > WebDAV Users.
6. Schedule (daily time / hourly). Multiple sends per day need a time-based file name.

Never ask the user to paste passwords, WebDAV secrets, or API keys into chat.

## Step 3. Verify the sources (read-only)

```bash
tdx describe <db>.<table>
tdx query --engine trino "SELECT <columns> FROM <db>.<table> WHERE <where> LIMIT 10"
tdx query --engine trino "SELECT COUNT(1) FROM <db>.<table> WHERE <where>"
```

- Run the exact `columns` / `where` that will go into the config, substituted by hand, to catch syntax errors and reserved words (`"order"`, `"timestamp"`).
- Check the row count matches expectations — a missing time filter turns a delta send into a full send.
- For SFTP, confirm the Authentication exists: `tdx connection list` / `tdx connection show <name>`.

## Step 4. Write the configs

- `common.yml`: set `send_method` and `td_api_endpoint`.
- `sftp.yml` / `webdav.yml`: set connection block, then one `targets` entry per dataset. Disable unused samples with `enabled: false` or delete them. Put targets only in the file(s) of the chosen method; with "both", define the targets each method should send.
- Apply Emarsys rules from `references/config_targets.md`:
  - contacts: a stable non-guessable external ID column; custom fields must already exist in Emarsys; date format must match the auto-import setting (e.g. `DD.MM.YYYY`); opt-in FALSE→TRUE can't be done by import.
  - sales_items: `file_prefix: "sales_items"`, lowercase headers, required `item, price, order, timestamp, customer|email, quantity` in the onboarded column order, ISO 8601 timestamp, no overlapping periods (no dedup on Emarsys side).
- `file_prefix` must match the Emarsys file-name pattern exactly (case-sensitive), otherwise files become `*.ignore`.
- Need JOINs or aggregation? Add `query/<name>.sql` using `${targets[target].*}` and set `query_file: <name>`.
- Only edit the dig if the user needs something the configs can't express (e.g. time in file name, schedule). Keep the fixed SFTP `result_settings` (`sequence_format: ""`, `rename_file_after_upload: true`, `header_line: true`) unless there is a reason.

## Step 5. Deploy and test

1. `tdx wf push <project_dir> --dry-run`, then `tdx wf push <project_dir>` after the user confirms.
2. WebDAV only: the user registers secrets `td.apikey`, `emarsys.webdav_user`, `emarsys.webdav_password` themselves (TD console > Workflows > project > Secrets, or `tdx wf secrets set <project> KEY=VALUE` in their own terminal). Check with `tdx wf secrets list <project>`.
3. `tdx wf run` sends real files to Emarsys and may update live contacts. Run `--dry-run` first, explain which targets, row counts, and destinations will be sent, and wait for explicit confirmation. For the first real run, suggest enabling one target with a small `where` (or a test Emarsys import).
4. After the run, check the TD log (`+echo_settings`, `[sftp]/[webdav]` echo, `rows=` from the Python task) and the Emarsys import log (`*.done` / `*.error`).

## Output format

Finish with:
1. A table: target / method / source table / rows (from COUNT) / file name / Emarsys pattern
2. The edited config files (open with `mcp__work__open_file`)
3. Remaining manual steps (Emarsys auto-import, Authentication, secrets, schedule) and open risks

## Example

**Input:** 「顧客マスタ cdp_audience_123.customers の前日更新分を contacts、ec_db.order_items の前日分を sales_items としてSFTPで毎朝6時にEmarsysへ送りたい。AuthenticationはEmarsys_SFTP、パスは/upload」

**Output (abridged):**
- `common.yml`: `send_method: {sftp: true, webdav: false}`
- `sftp.yml`: `connection_name: "Emarsys_SFTP"`, `base_dir: "/upload"`, targets `contacts` (`where: "TD_INTERVAL(time, '-1d', 'JST')"`, `file_prefix: "contacts"`) and `sales_items` (lowercase headers, `AS "order"`, `TO_ISO8601(...) AS "timestamp"`)
- dig: uncomment `schedule: daily>: 06:00:00`
- Table: contacts / sftp / customers / 12,340 / contacts_YYYYMMDD.csv / contacts_*.csv …
- Risk: sales_items column order must match the Smart Insight onboarding definition — confirm with the Emarsys admin.

## Edge cases

- Several sends per day: change `path_prefix` / `file_name` in the dig to include time; otherwise the same file is overwritten.
- File > ~1GB (WebDAV) or very large SFTP files: split into several targets by `where`.
- `customer` and `email` mixed in sales_items: pick one.
- Region mismatch: WebDAV job fetch returns 401/404 when `td_api_endpoint` points to the wrong region.
- Emarsys auto-import is per pattern: one target per pattern; don't send two datasets with the same prefix.
