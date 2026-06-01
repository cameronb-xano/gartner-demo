query "me" verb=GET {
  api_group = "iam"
  description = "Return the currently authenticated user"
  auth = "user"
  input {}
  stack {
    db.get "user" {
      field_name = "id"
      field_value = $auth.id
    } as $user

    precondition ($user != null) {
      error_type = "notfound"
      error = "User not found"
    }
  }
  response = { id: $user.id, name: $user.name, email: $user.email, role: $user.role, is_active: $user.is_active }
  guid = "gJGBRV8WZqiZTLi1PwbFRaCDEeQ"
}
