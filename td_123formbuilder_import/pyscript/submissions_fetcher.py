"""Read-only submission extraction. Full snapshot append (not incremental)."""
from pyscript.common import ApiClient, run


class FormBuilderSubmissionsClient(ApiClient):
    def fetch_all_submissions_data(self):
        records = []
        for form in self.items("forms"):
            form_id = form["id"]
            for submission in self.items(f"forms/{form_id}/submissions"):
                records.append({
                    "form_id": str(form_id),
                    "form_name": form.get("name"),
                    "form_status": form.get("active"),
                    "submission_id": submission["id"],
                    "submission_date": submission.get("date"),
                    "submission_content": submission.get("content"),
                    "submission_data": submission,
                })
        return records


def main():
    return run(FormBuilderSubmissionsClient, "fetch_all_submissions_data", "formbuilder_submissions")


if __name__ == "__main__":
    main()
