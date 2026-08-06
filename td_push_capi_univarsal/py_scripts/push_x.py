"""X (Twitter) Conversion API 送信タスク

Xにはコネクタが存在しないため、capi_send テーブルを直接クエリし、
X Ads API (POST /{version}/measurement/conversions/:pixel_id) へ
OAuth1.0a 署名付きリクエストとして送信する。

参考:
- https://developer.x.com/ja/docs/x-ads-api/measurement/web-conversions/conversions
- https://docs.x.com/x-ads-api/measurement/web-conversions
"""

import hashlib
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
API_VERSION = "12"
BATCH_SIZE = 1000  # X公式ドキュメントに明示的な上限記載はないが、安全のため分割送信する


def _install_requirements():
    req_path = BASE_DIR / "requirements.txt"
    if req_path.exists():
        os.system(f'{sys.executable} -m pip install -q -r "{req_path}"')


def _normalize_email(value):
    return value.strip().lower()


def _normalize_phone(value):
    # X は E.164 形式（先頭 "+" + 数字のみ）を要求する
    digits = "".join(ch for ch in value.strip() if ch.isdigit())
    return f"+{digits}"


def _sha256_hex(value):
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def _to_iso8601(unix_time):
    dt = datetime.fromtimestamp(int(unix_time), tz=timezone.utc)
    return dt.strftime("%Y-%m-%dT%H:%M:%S.000Z")


class PushX:
    def run(
        self,
        brand_name,
        database,
        x_pixel_id,
        x_event_id,
        x_consumer_key,
        x_consumer_secret,
        x_access_token,
        x_access_token_secret,
        email_hashed=False,
        phone_hashed=False,
    ):
        _install_requirements()

        import pytd
        import requests
        from requests_oauthlib import OAuth1

        client = pytd.Client(
            apikey=os.environ["TD_API_KEY"],
            database=database,
            default_engine="presto",
        )

        sql = (BASE_DIR / "query" / "push_x.sql").read_text()
        result = client.query(sql)
        columns = result["columns"]
        rows = [dict(zip(columns, row)) for row in result["data"]]

        if not rows:
            print(f"[push_x] {brand_name}: no rows to send, skipping")
            return

        conversions = []
        for row in rows:
            identifiers = []
            email = row.get("email")
            phone = row.get("phone_number")
            ip_address = row.get("ip_address")
            user_agent = row.get("user_agent")

            if email:
                hashed_email = (
                    email if email_hashed else _sha256_hex(_normalize_email(email))
                )
                identifiers.append({"hashed_email": hashed_email})
            if phone:
                hashed_phone = (
                    phone if phone_hashed else _sha256_hex(_normalize_phone(phone))
                )
                identifiers.append({"hashed_phone_number": hashed_phone})
            # ip_address / user_agent は単独では識別子として不十分なため、
            # 他の識別子と併用する場合のみ付与する
            if ip_address and user_agent and identifiers:
                identifiers.append({"ip_address": ip_address, "user_agent": user_agent})

            if not identifiers:
                # 少なくとも1つの識別子（Click ID/メール/電話）が必須
                continue

            conversions.append(
                {
                    "conversion_time": _to_iso8601(row["event_time"]),
                    "event_id": x_event_id,
                    "conversion_id": str(row["event_id"]),
                    "identifiers": identifiers,
                    "value": str(row["value"]) if row.get("value") is not None else "0",
                }
            )

        if not conversions:
            print(f"[push_x] {brand_name}: no valid conversions after filtering, skipping")
            return

        auth = OAuth1(
            x_consumer_key,
            client_secret=x_consumer_secret,
            resource_owner_key=x_access_token,
            resource_owner_secret=x_access_token_secret,
        )
        url = f"https://ads-api.x.com/{API_VERSION}/measurement/conversions/{x_pixel_id}"

        for i in range(0, len(conversions), BATCH_SIZE):
            batch = conversions[i : i + BATCH_SIZE]
            resp = requests.post(url, auth=auth, json={"conversions": batch}, timeout=30)
            if resp.status_code != 200:
                raise RuntimeError(
                    f"[push_x] {brand_name}: X Conversion API error "
                    f"{resp.status_code}: {resp.text}"
                )
            print(f"[push_x] {brand_name}: sent {len(batch)} conversions -> {resp.json()}")
