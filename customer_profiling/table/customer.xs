table "customer" {
  auth = false
  schema {
    int id
    timestamp created_at?=now
    text first_name filters=trim
    text last_name filters=trim
    email email filters=trim|lower
    text phone? filters=trim
    text policy_number? filters=trim|upper
    json address?
    decimal lifetime_value?=0 {
      description = "Sum of paid claims and premiums to date"
    }
    decimal risk_score?=0 {
      description = "0..100 risk score, higher = riskier"
    }
    enum segment?="standard" {
      values = ["new", "standard", "high_value", "at_risk", "churned"]
    }
    timestamp last_event_at?
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "email"}]}
    {type: "btree", field: [{name: "policy_number"}]}
    {type: "btree", field: [{name: "segment"}]}
    {type: "btree", field: [{name: "risk_score", op: "desc"}]}
  ]
  guid = "zf25yi9jQsYhpamBxMjz_LmT858"
}
