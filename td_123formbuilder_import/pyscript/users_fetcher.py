"""Read-only extraction using the documented GET /users endpoint only."""
from pyscript.common import ApiClient, run


class FormBuilderUsersClient(ApiClient):
    def fetch_all_users_data(self):
        # Do not infer a role from an undocumented is_subuser field.
        # Preserve user_parent and permission fields returned by the API.
        return list(self.items("users"))


def main():
    return run(FormBuilderUsersClient, "fetch_all_users_data", "formbuilder_users")


if __name__ == "__main__":
    main()
