table "notification" {
  auth = false
  schema {
    int id
    timestamp created_at?=now
    int customer_id {
      description = "Customer ID from Customer Profiling workspace"
    }
    text recipient filters=trim {
      description = "Email/phone/device target depending on channel"
    }
    enum channel {
      values = ["email", "sms", "push", "inapp"]
    }
    text template_name filters=trim
    text subject? filters=trim
    text body filters=trim
    enum status?="queued" {
      values = ["queued", "sent", "delivered", "failed", "bounced"]
    }
    text source? filters=trim {
      description = "Originating workspace/service e.g. tickets, billing"
    }
    json vars?
    json provider_response?
    timestamp sent_at?
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "customer_id"}, {name: "created_at", op: "desc"}]}
    {type: "btree", field: [{name: "status"}]}
    {type: "btree", field: [{name: "channel"}]}
    {type: "btree", field: [{name: "template_name"}]}
  ]
  guid = "ET0Qi7nJvickFfcMeHXXVA282_Q"
}
