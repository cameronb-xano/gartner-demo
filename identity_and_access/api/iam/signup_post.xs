query "signup" verb=POST {
  api_group = "iam"
  description = "Create a new user account, return a token"
  input {
    text name filters=trim
    email email filters=trim|lower
    password password filters=min:8
    enum role?="agent" {
      values = ["agent", "supervisor", "admin"]
    }
  }
  stack {
    db.has "user" {
      field_name = "email"
      field_value = $input.email
    } as $exists

    precondition (!$exists) {
      error_type = "inputerror"
      error = "An account with that email already exists"
    }

    db.add "user" {
      data = {
        name: $input.name,
        email: $input.email,
        password: $input.password,
        role: $input.role,
        is_active: true,
        created_at: now
      }
    } as $user

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
        source: "iam-signup",
        expires_at: now|transform_timestamp:"+1 day",
        created_at: now
      }
    }
  }
  response = {
    token: $token,
    user: { id: $user.id, name: $user.name, email: $user.email, role: $user.role }
  }
  guid = "x6brvSA9s7asL2szF3yC6Ks-wkU"
}
