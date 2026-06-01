query "verify" verb=POST {
  api_group = "iam"
  description = "Service-to-service: verify an auth token and return the matching user. Used by other workspaces (Tickets, Billing, Notifications) to authenticate incoming requests."
  input {
    text token filters=trim
  }
  stack {
    db.get "session" {
      field_name = "token"
      field_value = $input.token
    } as $session

    conditional {
      if ($session == null || $session.expires_at < now || $session.revoked_at != null) {
        var $valid { value = false }
        var $user { value = null }
      }
      else {
        var $valid { value = true }
        db.get "user" {
          field_name = "id"
          field_value = $session.user_id
        } as $user
      }
    }
  }
  response = {
    valid: $valid,
    user: $user
  }
  guid = "xmF78S1QNOMsujNAXBBrKfMvziY"
}
