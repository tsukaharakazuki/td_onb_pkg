"""Read-only 123FormBuilder group extraction."""
from pyscript.common import ApiClient, run


class FormBuilderGroupsClient(ApiClient):
    def fetch_all_groups_data(self):
        records = []
        for group in self.items("groups"):
            group_id = group["id"]
            details = self.detail(f"groups/{group_id}")
            # Official schema: data is GroupWithForms, NOT a list of forms.
            grouped = self.detail(f"groups/{group_id}/forms")
            forms = grouped.get("forms")
            if not isinstance(forms, list) or any(not isinstance(x, dict) for x in forms):
                raise RuntimeError(f"Group {group_id}: invalid forms field")
            records.append({**group, **details, "forms": forms, "forms_count": len(forms)})
        return records


def main():
    return run(FormBuilderGroupsClient, "fetch_all_groups_data", "formbuilder_groups")


if __name__ == "__main__":
    main()
