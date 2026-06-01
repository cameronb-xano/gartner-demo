table "notification_template" {
  auth = false
  schema {
    int id
    timestamp created_at?=now
    text name filters=trim {
      description = "Template key, e.g. claim_opened, claim_approved, payment_received"
    }
    enum channel {
      values = ["email", "sms", "push", "inapp"]
    }
    text subject? filters=trim
    text body filters=trim {
      description = "Body with {{var}} placeholders"
    }
    bool is_active?=true
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree|unique", field: [{name: "name"}, {name: "channel"}]}
  ]
  guid = "CcuNK476EHVoqpxc3J3nLr_HR0A"
}
