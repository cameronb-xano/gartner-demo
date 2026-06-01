query "users/{user_id}" verb=GET {
  api_group = "iam"
  description = "Lookup a user by ID. Used cross-workspace to enrich claim/ticket records with agent details."
  input {
    int user_id { table = "user" }
  }
  stack {
    db.get "user" {
      field_name = "id"
      field_value = $input.user_id
    } as $user

    precondition ($user != null) {
      error_type = "notfound"
      error = "User not found"
    }
  }
  response = { id: $user.id, name: $user.name, email: $user.email, role: $user.role, is_active: $user.is_active }
  guid = "1Lfby2TS-C9kmtRhSbavMx-eBW8"
}
