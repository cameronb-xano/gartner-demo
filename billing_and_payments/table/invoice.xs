table "invoice" {
  auth = false
  schema {
    int id
    timestamp created_at?=now
    int customer_id {
      description = "Customer ID from Customer Profiling workspace"
    }
    text claim_ref? filters=trim|upper {
      description = "Reference to a claim, e.g. CLM-2026-00001"
    }
    enum direction?="outbound" {
      values = ["outbound", "inbound"]
      description = "outbound = bill the customer (premium); inbound = pay the customer (claim payout)"
    }
    decimal amount filters=min:0
    text currency?="USD" filters=trim|upper
    enum status?="draft" {
      values = ["draft", "issued", "paid", "void", "refunded"]
    }
    text description? filters=trim
    timestamp due_at?
    timestamp paid_at?
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "customer_id"}]}
    {type: "btree", field: [{name: "claim_ref"}]}
    {type: "btree", field: [{name: "status"}]}
    {type: "btree", field: [{name: "due_at"}]}
  ]
  guid = "d9cU7l-i9HVVTdhxu6UleCWmK4c"
}
