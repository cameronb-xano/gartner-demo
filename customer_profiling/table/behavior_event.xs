table "behavior_event" {
  auth = false
  schema {
    int id
    timestamp created_at?=now
    int customer_id { table = "customer" }
    text source filters=trim {
      description = "Originating workspace: tickets, billing, notify, web, etc."
    }
    text event_type filters=trim {
      description = "e.g. claim_opened, claim_paid, payment_received, notification_sent"
    }
    json payload?
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "customer_id"}, {name: "created_at", op: "desc"}]}
    {type: "btree", field: [{name: "event_type"}]}
    {type: "btree", field: [{name: "source"}]}
  ]
  guid = "8P735J6QLQHkSbj-KV0Mza-CbTE"
}
