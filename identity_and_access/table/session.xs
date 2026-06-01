table "session" {
  auth = false
  schema {
    int id
    timestamp created_at?=now
    int user_id { table = "user" }
    text token filters=trim {
      description = "Issued auth token (opaque)"
      sensitive = true
    }
    text source? filters=trim {
      description = "Originating workspace/service e.g. tickets, billing"
    }
    timestamp expires_at
    timestamp revoked_at?
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree|unique", field: [{name: "token"}]}
    {type: "btree", field: [{name: "user_id"}]}
    {type: "btree", field: [{name: "expires_at"}]}
  ]
  guid = "cnHMvgiBYSZUw5K5DzLc_UeeqcY"
}
