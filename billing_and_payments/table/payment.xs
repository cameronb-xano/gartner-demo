table "payment" {
  auth = false
  schema {
    int id
    timestamp created_at?=now
    int invoice_id { table = "invoice" }
    decimal amount filters=min:0
    text currency?="USD" filters=trim|upper
    enum method {
      values = ["card", "ach", "wire", "check", "credit", "manual"]
    }
    text transaction_ref? filters=trim
    enum status?="succeeded" {
      values = ["pending", "succeeded", "failed", "refunded"]
    }
    json provider_payload?
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "invoice_id"}]}
    {type: "btree", field: [{name: "status"}]}
    {type: "btree|unique", field: [{name: "transaction_ref"}]}
  ]
  guid = "Mbxe2_oWpDfX5MPc7cV3qxxq4SI"
}
