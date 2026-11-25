"""Shared runtime. Import only standard-library modules until dependencies are installed."""
import importlib
import json
import logging
import os
from pathlib import Path
import re
import subprocess
import sys
import time
from datetime import datetime, timezone
from uuid import uuid4

logger = logging.getLogger(__name__)


def install_dependencies():
    requirements = Path(__file__).resolve().parent.parent / "requirements.txt"
    subprocess.run(
        [sys.executable, "-m", "pip", "install", "--quiet",
         "--disable-pip-version-check", "-r", str(requirements)],
        check=True,
    )
    importlib.invalidate_caches()


def required_env(name):
    # Credentials must reach the API byte-for-byte, including whitespace.
    value = os.environ.get(name, "")
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def safe_error(exc):
    message = str(exc)
    for name in ("TD_API_KEY", "FORMBUILDER_PASSWORD", "FORMBUILDER_USERNAME"):
        value = os.environ.get(name)
        if value:
            message = message.replace(value, "[REDACTED]")
    # API credentials are query parameters in the published v2 specification.
    message = re.sub(r"(?i)(JWT|password|passhash|username|email|apikey)=([^&\s]+)",
                     r"\1=[REDACTED]", message)
    return message[:1000]


class ApiClient:
    def __init__(self, username, password, base_url=None):
        import requests
        self.requests = requests
        self.base_url = (base_url or os.environ.get(
            "FORMBUILDER_BASE_URL", "https://api.123formbuilder.com/v2")).rstrip("/")
        if self.base_url not in ("https://api.123formbuilder.com/v2",
                                 "https://eu-api.123formbuilder.com/v2"):
            raise RuntimeError("FORMBUILDER_BASE_URL must be an official HTTPS v2 API URL")
        self.username = username
        self.password = password
        self.session = requests.Session()
        self.token = self._login()

    def _request(self, method, endpoint, **kwargs):
        # Do not propagate requests exceptions containing a credential-bearing URL.
        try:
            response = self.session.request(
                method, f"{self.base_url}/{endpoint}", timeout=(10, 120),
                allow_redirects=False, **kwargs)
        except self.requests.RequestException as exc:
            raise RuntimeError(f"123FormBuilder {endpoint}: {type(exc).__name__}") from None
        if not 200 <= response.status_code < 300:
            raise RuntimeError(f"123FormBuilder {endpoint}: HTTP {response.status_code}")
        try:
            payload = response.json()
        except ValueError:
            raise RuntimeError(f"123FormBuilder {endpoint}: response is not JSON") from None
        if not isinstance(payload, dict):
            raise RuntimeError(f"123FormBuilder {endpoint}: expected a JSON object")
        code = payload.get("status_code")
        if code is not None and str(code) not in ("200", "201"):
            raise RuntimeError(f"123FormBuilder {endpoint}: API status_code={code}")
        return payload

    def _login(self):
        payload = self._request("POST", "token", params={
            "username": self.username, "password": self.password})
        token = payload.get("token")
        if not isinstance(token, str) or not token:
            raise RuntimeError("123FormBuilder login response has no token")
        logger.info("123FormBuilder authentication completed")
        return token

    def get(self, endpoint, **params):
        payload = self._request("GET", endpoint, params={**params, "JWT": self.token})
        if "data" not in payload:
            raise RuntimeError(f"123FormBuilder {endpoint}: missing data field")
        return payload

    def detail(self, endpoint):
        data = self.get(endpoint)["data"]
        if not isinstance(data, dict):
            raise RuntimeError(f"123FormBuilder {endpoint}: expected object data")
        return dict(data)

    def items(self, endpoint):
        """Honor actual server pagination, even if the server caps page size."""
        page, previous_ids = 1, None
        while True:
            payload = self.get(endpoint, page=page, per_page=100)
            data = payload["data"]
            if not isinstance(data, list) or any(not isinstance(x, dict) for x in data):
                raise RuntimeError(f"123FormBuilder {endpoint}: expected list data")
            pagination = payload.get("meta", {}).get("pagination", {})
            total_pages = pagination.get("total_pages")
            if not data:
                total = pagination.get("total")
                # APIs may represent an empty collection as one empty page.
                # An empty source form must not prevent importing other forms.
                if page == 1 and (total is not None and int(total) == 0):
                    return
                if total_pages is not None and page <= int(total_pages):
                    raise RuntimeError(f"123FormBuilder {endpoint}: unexpectedly empty page {page}")
                return
            ids = tuple(str(item.get("id")) for item in data)
            if previous_ids == ids:
                raise RuntimeError(f"123FormBuilder {endpoint}: repeated page; refusing partial import")
            for item in data:
                if item.get("id") is None:
                    raise RuntimeError(f"123FormBuilder {endpoint}: record has no id")
                yield dict(item)
            previous_ids = ids
            if total_pages is not None:
                if page >= int(total_pages):
                    return
            else:
                # With no metadata, request until an empty page rather than assume page size.
                if page >= 100000:
                    raise RuntimeError("API pagination safety limit reached")
            page += 1

    def close(self):
        self.session.close()


def prepare_dataframe(records, batch_id, imported_at):
    import pandas as pd
    # Preserve nested structures as JSON, not invalid dotted TD column names.
    rows = []
    for record in records:
        row = {}
        for key, value in record.items():
            if not re.fullmatch(r"[a-z_][a-z0-9_]*", key):
                raise RuntimeError(f"Unsupported source column name: {key}")
            row[key] = json.dumps(value, ensure_ascii=False) if isinstance(value, (dict, list)) else value
        row.update(time=imported_at, extracted_at=datetime.fromtimestamp(
            imported_at, timezone.utc).isoformat(), import_run_id=batch_id)
        rows.append(row)
    # Build integer columns before pandas can infer float64 for int + None.
    # Passing a previously inferred float column to Int64 would be too late.
    columns = {}
    for key in dict.fromkeys(key for row in rows for key in row):
        values = [row.get(key) for row in rows]
        present = [value for value in values if value is not None]
        if present and all(type(value) is int for value in present):
            if all(-(2**63) <= value < 2**63 for value in present):
                dtype = "Int64" if len(present) != len(values) else "int64"
                columns[key] = pd.Series(values, dtype=dtype)
            else:
                # TD bigint is signed 64-bit. Preserve larger values as text.
                columns[key] = pd.Series(
                    [str(value) if value is not None else None for value in values], dtype=object)
        elif any(type(value) is int and abs(value) > 2**53 for value in present):
            # Mixed numeric types can also trigger lossy float inference.
            columns[key] = pd.Series(
                [str(value) if value is not None else None for value in values], dtype=object)
        else:
            columns[key] = pd.Series(values)
    return pd.DataFrame(columns)


def upload(records, table, database, api_key, endpoint):
    import pytd
    if not records:
        raise RuntimeError("API returned 0 records. Nothing was imported; check source data and API permissions.")
    batch_id, imported_at = uuid4().hex, int(time.time())
    frame = prepare_dataframe(records, batch_id, imported_at)
    logger.info("IMPORT_START target=%s.%s fetched=%d run_id=%s endpoint=%s",
                database, table, len(frame), batch_id, endpoint)
    client = pytd.Client(apikey=api_key, database=database, endpoint=endpoint)
    try:
        client.load_table_from_dataframe(frame, f"{database}.{table}",
                                         writer="bulk_import", if_exists="append", fmt="msgpack")
        # load_table_from_dataframe may only warn for rejected rows. Verify committed records.
        sql = (f'SELECT COUNT(*) AS cnt FROM "{database}"."{table}" '
               f"WHERE time = {imported_at} AND import_run_id = '{batch_id}'")
        loaded = 0
        for attempt in range(6):
            result = client.query(sql, engine="presto")
            loaded = int(result["data"][0][0])
            if loaded == len(frame):
                break
            if attempt < 5:
                time.sleep(10)
        if loaded != len(frame):
            raise RuntimeError(f"TD verification mismatch: expected={len(frame)} actual={loaded} "
                               f"run_id={batch_id}. Data may already be committed; do not blindly retry.")
        logger.info("IMPORT_SUCCESS target=%s.%s fetched=%d verified=%d run_id=%s",
                    database, table, len(frame), loaded, batch_id)
        return loaded
    except Exception as exc:
        raise RuntimeError(f"TD import/verification failed target={database}.{table} "
                           f"run_id={batch_id}: {safe_error(exc)}. "
                           "Check committed data before retrying.") from None
    finally:
        client.close()


def run(client_type, fetch_method, table):
    logging.basicConfig(level=logging.INFO)
    try:
        # Validate configuration BEFORE calling the source API or installing packages.
        username, password = required_env("FORMBUILDER_USERNAME"), required_env("FORMBUILDER_PASSWORD")
        api_key, database = required_env("TD_API_KEY"), required_env("TD_DATABASE").strip()
        if database == "your_database_name" or not re.fullmatch(r"[a-z0-9_]+", database):
            raise RuntimeError("Set the real td.database in config/params.yml")
        endpoint = os.environ.get("TD_API_SERVER", "https://api.treasuredata.com").strip().rstrip("/")
        if not endpoint.startswith("https://"):
            endpoint = "https://" + endpoint
        if endpoint not in {"https://api.treasuredata.com", "https://api.treasuredata.co.jp",
                            "https://api.eu01.treasuredata.com", "https://api.ap02.treasuredata.com"}:
            raise RuntimeError("TD_API_SERVER must be an official TD regional HTTPS endpoint")
        install_dependencies()
        client = client_type(username, password)
        try:
            records = getattr(client, fetch_method)()
        finally:
            client.close()
        return upload(records, table, database, api_key, endpoint)
    except Exception as exc:
        logger.error("IMPORT_FAILED %s", safe_error(exc))
        # Do not expose credential-bearing chained exceptions in Digdag logs.
        raise RuntimeError(safe_error(exc)) from None
