table "ticket" {
  auth = false
  schema {
    int id
    timestamp created_at?=now
    timestamp updated_at?
    int claim_id? {
      description = "Owning claim id; null for standalone support tickets"
    }
    int created_by {
      description = "User id of who created the ticket"
    }
    int assigned_to? {
      description = "Currently assigned user id"
    }
    text subject filters=trim
    text body filters=trim
    enum status?="open" {
      values = ["open", "pending", "resolved", "closed"]
    }
    enum priority?="medium" {
      values = ["low", "medium", "high", "urgent"]
    }
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "claim_id"}]}
    {type: "btree", field: [{name: "assigned_to"}]}
    {type: "btree", field: [{name: "status"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
  guid = "uV4pR4cJ5lBgSTX9IpAQJP8hrIA"
}
