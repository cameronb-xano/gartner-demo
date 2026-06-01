query "login" verb=POST {
  api_group = "iam"
  description = "Exchange email + password for an auth token"
  input {
    email email filters=trim|lower
    text password { sensitive = true }
    text source? filters=trim {
      description = "Optional source label, e.g. tickets|billing|web"
    }
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

    db.add "session" {
      data = {
        user_id: $user.id,
        token: $token,
        source: $input.source,
        expires_at: now|transform_timestamp:"+1 day",
        created_at: now
      }
    }
  }
  response = {
    token: $token,
    user: { id: $user.id, name: $user.name, email: $user.email, role: $user.role }
  }
  guid = "tP8dawI5GCxhuNkAjDMUm0zoQc4"
}
