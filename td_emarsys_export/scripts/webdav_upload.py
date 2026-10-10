"""TDジョブ結果をCSV化し、Emarsys WebDAV へ PUT でアップロードする。

td> タスクの直後に py> で呼び出し、${td.last_job_id} を job_id として受け取る。
認証情報は環境変数（_env）で受け取る: TD_API_KEY / WEBDAV_USER / WEBDAV_PASSWORD
"""
import csv
import json
import os
import subprocess
import sys
import tempfile
import time

NEWLINES = {"CRLF": "\r\n", "LF": "\n", "CR": "\r"}
DELIMITERS = {"tab": "\t", "\\t": "\t"}


def _install_packages():
    subprocess.check_call(
        [sys.executable, "-m", "pip", "install", "--quiet", "td-client", "requests"]
    )


def _to_bool(value):
    return str(value).strip().lower() in ("true", "1", "yes")


def _format_value(value):
    if value is None:
        return ""
    if isinstance(value, (list, dict)):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, bool):
        return "true" if value else "false"
    return value


def _write_csv(job, path, delimiter, newline):
    columns = [c[0] for c in job.result_schema]
    rows = 0
    # Emarsys の要件: UTF-8 / 1行目ヘッダー
    with open(path, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(
            f, delimiter=delimiter, lineterminator=newline, quoting=csv.QUOTE_MINIMAL
        )
        writer.writerow(columns)
        for row in job.result():
            writer.writerow([_format_value(v) for v in row])
            rows += 1
    return rows


def _put(url, path, auth, timeout, retry=3):
    import requests

    for attempt in range(1, retry + 1):
        try:
            with open(path, "rb") as f:
                res = requests.put(
                    url,
                    data=f,
                    auth=auth,
                    timeout=timeout,
                    headers={"Content-Type": "text/csv; charset=utf-8"},
                )
            if res.status_code in (200, 201, 204):
                return res.status_code
            raise RuntimeError("HTTP {}: {}".format(res.status_code, res.text[:500]))
        except Exception as e:
            if attempt == retry:
                raise
            wait = 10 * attempt
            print("PUT failed ({}/{}): {} -> retry in {}s".format(attempt, retry, e, wait))
            time.sleep(wait)


def main(
    job_id,
    td_endpoint,
    base_url,
    directory,
    file_name,
    delimiter=",",
    newline="CRLF",
    skip_if_empty="true",
    timeout_sec="600",
):
    _install_packages()
    import tdclient

    delimiter = DELIMITERS.get(str(delimiter), str(delimiter))
    newline = NEWLINES[str(newline).upper()]
    url = "/".join(
        p.strip("/") for p in [str(base_url), str(directory), str(file_name)] if str(p).strip("/")
    )
    auth = (os.environ["WEBDAV_USER"], os.environ["WEBDAV_PASSWORD"])

    with tdclient.Client(apikey=os.environ["TD_API_KEY"], endpoint=td_endpoint) as client:
        job = client.job(int(job_id))
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, str(file_name))
            rows = _write_csv(job, path, delimiter, newline)
            size = os.path.getsize(path)
            print("job_id={} rows={} bytes={} file={}".format(job_id, rows, size, file_name))

            if rows == 0 and _to_bool(skip_if_empty):
                print("0 rows -> skip upload")
                return

            status = _put(url, path, auth, int(timeout_sec))
            print("uploaded: {} (HTTP {})".format(url, status))
