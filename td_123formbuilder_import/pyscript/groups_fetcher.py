"""Read-only 123FormBuilder group extraction."""
from pyscript.common import ApiClient, as_list, run


class FormBuilderGroupsClient(ApiClient):
    def fetch_all_groups_data(self):
        records = []
        for group in self.items("groups"):
            group_id = group["id"]
            details = self.detail(f"groups/{group_id}")
            # Swagger documents data as GroupWithForms ({"forms": [...]}), but the
            # endpoint is described as a list. Accept both shapes; reject others.
            data = self.get(f"groups/{group_id}/forms")["data"]
            forms = as_list(data.get("forms")) if isinstance(data, dict) else as_list(data)
            if forms is None:
                raise RuntimeError(f"Group {group_id}: unexpected groups/{{id}}/forms response shape")
            records.append({**group, **details, "forms": forms, "forms_count": len(forms)})
        return records


def main():
    return run(FormBuilderGroupsClient, "fetch_all_groups_data", "formbuilder_groups")


if __name__ == "__main__":
    main()
