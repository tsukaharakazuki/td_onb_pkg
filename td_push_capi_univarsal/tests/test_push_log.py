"""送信ログ・ブランド別再実行のローカル回帰テスト（TDや広告APIには接続しない）。

実行: python3 -I -m unittest discover -s tests -v
SQLiteで実際のstage/insert SQLを検証する。Trino・コネクタの実機テストではない。
"""

import re
import sqlite3
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LOG_COLUMNS = (
    "event_name", "event_time", "em", "ph", "fn", "ln", "country", "value",
    "currency", "event_source_url", "action_source", "client_user_agent",
    "client_ip_address", "event_id", "push_time", "brand_name", "source_type",
    "platform",
)
EMAIL_PLATFORMS = (
    "facebook", "tiktok", "google_store_sales", "google_enhanced_web",
    "pinterest", "snapchat", "x",
)


def query(name, brand="brand_a", platform="facebook"):
    sql = (ROOT / "query" / name).read_text(encoding="utf-8")
    return sql.replace("${b.brand_name}", brand).replace("${b.platform}", platform)


class PushLogTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(":memory:")
        self.addCleanup(self.db.close)
        self.db.create_function("TD_SCHEDULED_TIME", 0, lambda: 1700000000)
        self.db.execute("""
            CREATE TABLE capi_base (
                event_name TEXT, event_time INTEGER, event_id TEXT,
                em TEXT, ph TEXT, country TEXT, value INTEGER, currency TEXT,
                event_source_url TEXT, action_source TEXT, client_user_agent TEXT,
                client_ip_address TEXT, member_id TEXT, source_type TEXT
            )
        """)
        self.db.execute("CREATE TABLE capi_push_log (%s)" % ", ".join(LOG_COLUMNS))
        self.add_event("E1", "first@example.test")
        self.add_event("E2", "")
        self.add_event("E3", "third@example.test")
        self.add_event("E4", None)

    def add_event(self, event_id, email):
        self.db.execute("""
            INSERT INTO capi_base VALUES (
                'Purchase', 1700000000, ?, ?, NULL, NULL, 100, 'JPY',
                NULL, 'website', NULL, NULL, NULL, 'daily'
            )
        """, (event_id, email))

    def stage(self, brand="brand_a", platform="facebook", initial=False):
        self.db.execute("DROP TABLE IF EXISTS capi_send")
        filename = "stage_brand_initial.sql" if initial else "stage_brand.sql"
        self.db.execute("CREATE TABLE capi_send AS " + query(filename, brand, platform))
        return {row[0] for row in self.db.execute("SELECT event_id FROM capi_send")}

    def log(self, brand="brand_a", platform="facebook"):
        self.db.execute("INSERT INTO capi_push_log (%s) %s" % (
            ", ".join(LOG_COLUMNS), query("insert_push_log.sql", brand, platform),
        ))

    def logged(self, brand="brand_a", platform="facebook"):
        return {row[0] for row in self.db.execute(
            "SELECT event_id FROM capi_push_log WHERE brand_name=? AND platform=?",
            (brand, platform),
        )}

    def test_initial_staging_does_not_reference_missing_log(self):
        self.db.execute("DROP TABLE capi_push_log")
        self.assertEqual(self.stage(initial=True), {"E1", "E2", "E3", "E4"})

    def test_only_email_eligible_rows_are_logged(self):
        self.stage()
        self.log()
        self.assertEqual(self.logged(), {"E1", "E3"})
        self.assertEqual(self.stage(), {"E2", "E4"})

    def test_export_and_log_have_the_same_email_filter(self):
        self.stage()
        logged_predicate = query("insert_push_log.sql").rsplit("WHERE", 1)[1]
        for platform in EMAIL_PLATFORMS:
            with self.subTest(platform=platform):
                predicate = query("push_%s.sql" % platform).rsplit("WHERE", 1)[1]
                normalize = lambda value: re.sub(r"\s+", " ", value).strip()
                self.assertEqual(normalize(predicate), normalize(logged_predicate))
                self.assertEqual(
                    {row[0] for row in self.db.execute(
                        "SELECT event_id FROM capi_send WHERE " + predicate,
                    )}, {"E1", "E3"},
                )

    def test_other_brand_is_not_excluded(self):
        self.stage()
        self.log()
        self.assertEqual(self.stage("brand_b"), {"E1", "E2", "E3", "E4"})

    def test_other_platform_is_not_excluded(self):
        self.stage()
        self.log()
        self.assertEqual(self.stage(platform="tiktok"), {"E1", "E2", "E3", "E4"})

    def test_failed_brand_remains_pending_after_restart(self):
        self.stage("brand_a")
        self.log("brand_a")
        self.stage("brand_b")
        # brand_b送信失敗: ログINSERTへ進まない。その後WFを先頭から再実行。
        self.assertEqual(self.stage("brand_a"), {"E2", "E4"})
        self.assertEqual(self.stage("brand_b"), {"E1", "E2", "E3", "E4"})
        self.log("brand_b")
        self.assertEqual(self.logged("brand_b"), {"E1", "E3"})

    def test_partial_prior_log_does_not_skip_entire_brand(self):
        self.db.execute("""
            INSERT INTO capi_push_log (event_id, brand_name, platform)
            VALUES ('E1', 'brand_a', 'facebook')
        """)
        self.assertEqual(self.stage(), {"E2", "E3", "E4"})
        self.log()
        self.assertEqual(self.logged(), {"E1", "E3"})

    def test_daily_new_event_is_not_blocked_by_hourly_log(self):
        self.stage()
        self.log()
        self.add_event("E5", "new@example.test")
        self.assertEqual(self.stage(), {"E2", "E4", "E5"})
        self.log()
        self.assertEqual(self.logged(), {"E1", "E3", "E5"})

    def test_email_added_later_can_be_sent(self):
        self.stage()
        self.log()
        self.db.execute("UPDATE capi_base SET em='later@example.test' WHERE event_id='E2'")
        self.stage()
        self.log()
        self.assertEqual(self.logged(), {"E1", "E2", "E3"})

    def test_legacy_null_platform_is_scoped_to_brand(self):
        self.db.execute("""
            INSERT INTO capi_push_log (event_id, brand_name, platform)
            VALUES ('E1', 'brand_a', NULL)
        """)
        self.assertEqual(self.stage(), {"E2", "E3", "E4"})
        self.assertEqual(self.stage("brand_b"), {"E1", "E2", "E3", "E4"})


if __name__ == "__main__":
    unittest.main()
