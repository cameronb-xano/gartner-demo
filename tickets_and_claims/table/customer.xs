table "customer" {
  auth = false
  schema {
    int id
    timestamp created_at?=now
    text first_name filters=trim
    text last_name filters=trim
    email email filters=trim|lower
    text phone? filters=trim
    text policy_number? filters=trim|upper {
      description = "External policy / account reference"
    }
    json address?
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "email"}]}
    {type: "btree", field: [{name: "policy_number"}]}
  ]
  guid = "knP7icBR9hNnbqMr9Y-IOuU8GO8"
}
