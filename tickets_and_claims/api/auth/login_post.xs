query "login" verb=POST {
  api_group = "auth"
  description = "Exchange email + password for an auth token"
  input {
    email email filters=trim|lower
    text password { sensitive = true }
  }
  stack {
    db.get "user" {
      field_name = "email"
      field_value = $input.email
    } as $user

    precondition ($user != null) {
      error_type = "accessdenied"
      error = "Invalid email or password"
    }

    precondition ($user.is_active == true) {
      error_type = "accessdenied"
      error = "This account is disabled"
    }

    security.check_password {
      text_password = $input.password
      hash_password = $user.password
    } as $is_valid

    precondition ($is_valid) {
      error_type = "accessdenied"
      error = "Invalid email or password"
    }

    security.create_auth_token {
      table = "user"
      id = $user.id
      extras = { role: $user.role, name: $user.name }
      expiration = 86400
    } as $token
  }
  response = {
    token: $token,
    user: { id: $user.id, name: $user.name, email: $user.email, role: $user.role }
  }
  guid = "a99l4_S0Q_Hlp3H7ep6KrGTW8C8"
}
