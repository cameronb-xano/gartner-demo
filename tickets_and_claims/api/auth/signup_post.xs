query "signup" verb=POST {
  api_group = "auth"
  description = "Create a new agent account and return an auth token"
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
  }
  response = {
    token: $token,
    user: { id: $user.id, name: $user.name, email: $user.email, role: $user.role }
  }
  guid = "M1zxa2kITS3GODhnnLPa1Oh5fFI"
}
