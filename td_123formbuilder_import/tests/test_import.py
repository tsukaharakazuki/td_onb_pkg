"""Offline regression tests. No API calls, package installs, or TD writes."""
import json
import os
from pathlib import Path
import unittest
from unittest.mock import MagicMock, patch

import pandas as pd
from pyscript import common
from pyscript.forms_fetcher import FormBuilderFormsClient
from pyscript.groups_fetcher import FormBuilderGroupsClient
from pyscript.submissions_fetcher import FormBuilderSubmissionsClient
from pyscript.users_fetcher import FormBuilderUsersClient


class RuntimeTests(unittest.TestCase):
    def setUp(self):
        self.env = patch.dict(os.environ, {
            "FORMBUILDER_USERNAME": "demo_user", "FORMBUILDER_PASSWORD": "demo_password",
            "TD_API_KEY": "fake_key", "TD_DATABASE": "test_db",
            "TD_API_SERVER": "api.treasuredata.co.jp",
        }, clear=True)
        self.env.start()
        self.addCleanup(self.env.stop)

    def test_missing_key_fails_before_install_or_api(self):
        del os.environ["TD_API_KEY"]
        factory = MagicMock()
        with patch.object(common, "install_dependencies") as install:
            with self.assertRaisesRegex(RuntimeError, "Missing.*TD_API_KEY"):
                common.run(factory, "fetch", "formbuilder_groups")
        install.assert_not_called()
        factory.assert_not_called()

    def test_run_preserves_credential_whitespace(self):
        os.environ["FORMBUILDER_USERNAME"] = " demo_user "
        os.environ["FORMBUILDER_PASSWORD"] = " demo_password "
        os.environ["TD_API_KEY"] = " fake_key "
        factory = MagicMock()
        factory.return_value.fetch.return_value = [{"id": 1}]
        with patch.object(common, "install_dependencies"), patch.object(common, "upload") as upload:
            common.run(factory, "fetch", "formbuilder_groups")
        factory.assert_called_once_with(" demo_user ", " demo_password ")
        self.assertEqual(upload.call_args.args[3], " fake_key ")

    def test_nullable_integers_through_real_writer(self):
        from pytd.writer import _cast_dtypes, _replace_pd_na
        cases = [
            ([9007199254740993, None], [9007199254740993, None]),
            ([123, None], [123, None]),
            ([2**63 - 1, None], [2**63 - 1, None]),
            ([2**63, None], [str(2**63), None]),
            ([9007199254740993, 1.5, None], ["9007199254740993", "1.5", None]),
        ]
        for values, expected in cases:
            with self.subTest(values=values):
                frame = common.prepare_dataframe([{"parent_id": value} for value in values], "batch", 1700000000)
                _cast_dtypes(frame)
                _replace_pd_na(frame)
                payloads = frame.to_dict(orient="records")
                self.assertEqual([item["parent_id"] for item in payloads], expected)
                self.assertIsNone(payloads[-1]["parent_id"])

    def test_placeholder_db_fails_before_api(self):
        os.environ["TD_DATABASE"] = "your_database_name"
        with self.assertRaisesRegex(RuntimeError, "real td.database"):
            common.run(MagicMock(), "fetch", "formbuilder_groups")

    def test_dependency_failure_stops(self):
        factory = MagicMock()
        with patch.object(common, "install_dependencies", side_effect=RuntimeError("pip failed")):
            with self.assertRaisesRegex(RuntimeError, "pip failed"):
                common.run(factory, "fetch", "formbuilder_groups")
        factory.assert_not_called()

    def test_api_failure_never_loads_partial_data(self):
        factory = MagicMock()
        factory.return_value.fetch.side_effect = RuntimeError("API failure")
        with patch.object(common, "install_dependencies"), patch.object(common, "upload") as upload:
            with self.assertRaisesRegex(RuntimeError, "API failure"):
                common.run(factory, "fetch", "formbuilder_groups")
        upload.assert_not_called()
        factory.return_value.close.assert_called_once()

    def test_prepare_dataframe_preserves_nested_and_leading_zeros(self):
        frame = common.prepare_dataframe([
            {"id": 1, "name": "00123", "forms": [{"id": 2}], "permissions": {"a": True}}
        ], "batch", 1700000000)
        self.assertEqual(frame.loc[0, "name"], "00123")
        self.assertEqual(json.loads(frame.loc[0, "forms"]), [{"id": 2}])
        self.assertEqual(json.loads(frame.loc[0, "permissions"]), {"a": True})
        self.assertEqual(frame.loc[0, "import_run_id"], "batch")
        self.assertEqual(int(frame.loc[0, "time"]), 1700000000)
        self.assertIsNotNone(frame.loc[0, "extracted_at"])

    def test_zero_records_fails_without_td_call(self):
        with patch("pytd.Client") as factory:
            with self.assertRaisesRegex(RuntimeError, "0 records"):
                common.upload([], "formbuilder_groups", "test_db", "fake", "https://api.treasuredata.com")
        factory.assert_not_called()

    def test_load_failure_propagates_no_success(self):
        with patch("pytd.Client") as factory, self.assertLogs(common.logger, level="INFO") as logs:
            factory.return_value.load_table_from_dataframe.side_effect = RuntimeError("load failed")
            with self.assertRaisesRegex(RuntimeError, "load failed"):
                common.upload([{"id": 1}], "formbuilder_groups", "test_db", "fake", "https://api.treasuredata.com")
        self.assertNotIn("IMPORT_SUCCESS", " ".join(logs.output))
        factory.return_value.close.assert_called_once()
        factory.return_value.query.assert_not_called()

    def test_success_requires_matching_query_count(self):
        with patch("pytd.Client") as factory, self.assertLogs(common.logger, level="INFO") as logs:
            factory.return_value.query.return_value = {"data": [[1]]}
            count = common.upload([{"id": 1}], "formbuilder_groups", "test_db", "fake", "https://api.treasuredata.co.jp")
        self.assertEqual(count, 1)
        self.assertIn("verified=1", " ".join(logs.output))
        call = factory.return_value.load_table_from_dataframe.call_args
        self.assertEqual(call.args[1], "test_db.formbuilder_groups")
        self.assertEqual(call.kwargs["if_exists"], "append")
        self.assertEqual(call.kwargs["fmt"], "msgpack")
        self.assertIsInstance(call.args[0], pd.DataFrame)
        self.assertIn("import_run_id", factory.return_value.query.call_args.args[0])
        self.assertEqual(factory.call_args.kwargs["endpoint"], "https://api.treasuredata.co.jp")

    def test_verification_mismatch_fails_and_warns_about_retry(self):
        with patch("pytd.Client") as factory, patch.object(common.time, "sleep"), self.assertLogs(common.logger, level="INFO") as logs:
            factory.return_value.query.return_value = {"data": [[0]]}
            with self.assertRaisesRegex(RuntimeError, "do not blindly retry"):
                common.upload([{"id": 1}], "formbuilder_groups", "test_db", "fake", "https://api.treasuredata.com")
        self.assertEqual(factory.return_value.query.call_count, 6)
        self.assertNotIn("IMPORT_SUCCESS", " ".join(logs.output))

    def test_safe_error_redacts(self):
        text = common.safe_error(RuntimeError("password=demo_password&JWT=secret_token key=fake_key"))
        self.assertNotIn("demo_password", text)
        self.assertNotIn("secret_token", text)
        self.assertNotIn("fake_key", text)


class ApiTests(unittest.TestCase):
    def response(self, payload, status=200):
        return MagicMock(status_code=status, json=MagicMock(return_value=payload))

    def test_spec_auth_and_request_shape(self):
        with patch("requests.Session") as factory:
            factory.return_value.request.side_effect = [
                self.response({"token": "test_token", "status_code": 200}),
                self.response({"data": [], "status_code": 200}),
            ]
            client = common.ApiClient("user", "password")
            client.get("groups", page=1)
        login, get = factory.return_value.request.call_args_list
        self.assertEqual(login.args[0], "POST")
        self.assertEqual(login.kwargs["params"], {"username": "user", "password": "password"})
        self.assertEqual(get.kwargs["params"]["JWT"], "test_token")
        self.assertFalse(login.kwargs["allow_redirects"])
        self.assertIn("timeout", get.kwargs)

    def test_http_failure_does_not_echo_secret_body(self):
        with patch("requests.Session") as factory:
            factory.return_value.request.return_value = self.response({"token": "private"}, 403)
            with self.assertRaisesRegex(RuntimeError, "HTTP 403") as caught:
                common.ApiClient("user", "password")
        self.assertNotIn("private", str(caught.exception))
        self.assertNotIn("password", str(caught.exception))

    def client_without_network(self, cls=common.ApiClient):
        return object.__new__(cls)

    def test_missing_data_is_not_empty_success(self):
        client = self.client_without_network()
        client.token = "test"
        client._request = MagicMock(return_value={"status_code": 200})
        with self.assertRaisesRegex(RuntimeError, "missing data"):
            client.get("groups")

    def test_pagination_honors_metadata_on_short_pages(self):
        client = self.client_without_network()
        client.get = MagicMock(side_effect=[
            {"data": [{"id": 1}], "meta": {"pagination": {"total_pages": 2}}},
            {"data": [{"id": 2}], "meta": {"pagination": {"total_pages": 2}}},
        ])
        self.assertEqual([x["id"] for x in client.items("groups")], [1, 2])

    def test_empty_first_page_with_total_zero_is_valid(self):
        client = self.client_without_network()
        client.get = MagicMock(return_value={
            "data": [], "meta": {"pagination": {"total": 0, "total_pages": 1}}})
        self.assertEqual(list(client.items("forms/1/submissions")), [])

    def test_unexpected_empty_page_with_nonzero_total_fails(self):
        client = self.client_without_network()
        client.get = MagicMock(return_value={
            "data": [], "meta": {"pagination": {"total": 5, "total_pages": 1}}})
        with self.assertRaisesRegex(RuntimeError, "unexpectedly empty"):
            list(client.items("forms/1/submissions"))

    def test_empty_form_does_not_block_other_submission_data(self):
        client = self.client_without_network(FormBuilderSubmissionsClient)
        def get(endpoint, **params):
            if endpoint == "forms":
                return {"data": [{"id": 1}, {"id": 2}],
                        "meta": {"pagination": {"total": 2, "total_pages": 1}}}
            if endpoint == "forms/1/submissions":
                return {"data": [], "meta": {"pagination": {"total": 0, "total_pages": 1}}}
            if endpoint == "forms/2/submissions":
                return {"data": [{"id": 3, "content": "{}"}],
                        "meta": {"pagination": {"total": 1, "total_pages": 1}}}
            self.fail(f"Unexpected endpoint {endpoint}")
        client.get = get
        records = client.fetch_all_submissions_data()
        self.assertEqual(len(records), 1)
        self.assertEqual(records[0]["form_id"], "2")
        self.assertEqual(records[0]["submission_id"], 3)

    def test_repeat_page_fails_instead_of_looping(self):
        client = self.client_without_network()
        client.get = MagicMock(return_value={"data": [{"id": 1}]})
        with self.assertRaisesRegex(RuntimeError, "repeated page"):
            list(client.items("groups"))

    def test_group_object_response_not_treated_as_list(self):
        client = self.client_without_network(FormBuilderGroupsClient)
        client.items = MagicMock(return_value=iter([{"id": 1, "name": "group"}]))
        client.detail = MagicMock(side_effect=[{"id": 1}, {"id": 1, "forms": [{"id": 2}]}])
        records = client.fetch_all_groups_data()
        self.assertEqual(records[0]["forms"], [{"id": 2}])
        self.assertEqual(records[0]["forms_count"], 1)

    def test_form_controls_and_total(self):
        client = self.client_without_network(FormBuilderFormsClient)
        client.items = MagicMock(return_value=iter([{"id": 1}]))
        client.detail = MagicMock(side_effect=[{"id": 1}, {"controls": {"data": [{"id": 3}]}}])
        client.get = MagicMock(return_value={"data": [], "meta": {"pagination": {"total": 12}}})
        record = client.fetch_all_forms_data()[0]
        self.assertEqual(record["fields"], [{"id": 3}])
        self.assertEqual(record["submissions_count"], 12)

    def test_users_only_documented_list(self):
        client = self.client_without_network(FormBuilderUsersClient)
        client.items = MagicMock(return_value=iter([{"id": 1, "user_parent": 0}]))
        self.assertEqual(len(client.fetch_all_users_data()), 1)
        client.items.assert_called_once_with("users")

    def test_submission_payload_kept(self):
        client = self.client_without_network(FormBuilderSubmissionsClient)
        submission = {"id": 3, "content": '{"answer":"00123"}', "date": "2026-11-25"}
        client.items = MagicMock(side_effect=[iter([{"id": 1, "active": 1}]), iter([submission])])
        record = client.fetch_all_submissions_data()[0]
        self.assertEqual(record["submission_content"], submission["content"])
        self.assertEqual(record["submission_data"], submission)
        self.assertEqual(record["form_status"], 1)


class WorkflowTests(unittest.TestCase):
    def test_workflows_have_ddl_and_direct_secrets_no_fake_success(self):
        import yaml
        root = Path(__file__).resolve().parent.parent
        class Loader(yaml.SafeLoader):
            pass
        Loader.add_constructor("!include", lambda loader, node: "!include")
        params = yaml.safe_load((root / "config/params.yml").read_text())
        for name in ("groups", "forms", "users", "submissions"):
            text = (root / f"td_{name}.dig").read_text()
            doc = yaml.load(text, Loader=Loader)
            self.assertEqual(doc["+create_table"]["create_tables"], [f"formbuilder_{name}"])
            task = doc[f"+extract_{name}"]
            self.assertEqual(task["docker"]["image"], "treasuredata/customscript-python:3.12.11-td4")
            self.assertEqual(task["_env"]["TD_API_KEY"], "${secret:td.apikey}")
            self.assertEqual(task["_env"]["TD_API_SERVER"], "${td.endpoint}")
            self.assertNotIn("+store_", text)
            self.assertNotIn("schedule", doc)
        self.assertIn("endpoint", params["td"])


if __name__ == "__main__":
    unittest.main()
