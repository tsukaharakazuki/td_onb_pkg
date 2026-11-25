"""Read-only 123FormBuilder form extraction."""
from pyscript.common import ApiClient, run


class FormBuilderFormsClient(ApiClient):
    def fetch_all_forms_data(self):
        records = []
        for form in self.items("forms"):
            form_id = form["id"]
            details = self.detail(f"forms/{form_id}")
            with_fields = self.detail(f"forms/{form_id}/fields")
            # Official schema: data.controls.data contains the controls.
            fields = with_fields.get("controls", {}).get("data")
            if not isinstance(fields, list):
                raise RuntimeError(f"Form {form_id}: invalid controls.data field")
            submissions = self.get(f"forms/{form_id}/submissions", page=1, per_page=10)
            sample = submissions["data"]
            if not isinstance(sample, list):
                raise RuntimeError(f"Form {form_id}: invalid submissions data")
            count = submissions.get("meta", {}).get("pagination", {}).get("total")
            if count is None:
                count = details.get("submissions_count")
            records.append({**form, **details, "fields": fields,
                            "submissions_sample": sample, "submissions_count": count})
        return records


def main():
    return run(FormBuilderFormsClient, "fetch_all_forms_data", "formbuilder_forms")


if __name__ == "__main__":
    main()
