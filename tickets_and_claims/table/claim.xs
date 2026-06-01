table "claim" {
  auth = false
  schema {
    int id
    timestamp created_at?=now
    text claim_number filters=trim|upper {
      description = "Human-readable claim reference, e.g. CLM-2026-00001"
    }
    int customer_id {
      table = "customer"
    }
    int assigned_agent_id? {
      description = "Currently assigned agent user id (nullable for unassigned)"
    }
    enum assigned_queue? {
      description = "Specialist queue selected by escalation routing"
      values = ["unassigned", "auto_specialist", "property_specialist", "liability_specialist", "catastrophe_review", "complex_claims", "general_review"]
    }
    enum claim_type {
      values = ["auto", "property", "health", "liability", "travel", "other"]
    }
    enum status?="new" {
      values = ["new", "in_review", "awaiting_info", "approved", "denied", "paid", "closed"]
    }
    enum priority?="medium" {
      values = ["low", "medium", "high", "urgent"]
    }
    decimal amount_requested filters=min:0
    decimal amount_approved? filters=min:0
    text summary filters=trim
    timestamp opened_at?=now
    timestamp closed_at?
    timestamp sla_due_at?
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree|unique", field: [{name: "claim_number"}]}
    {type: "btree", field: [{name: "customer_id"}]}
    {type: "btree", field: [{name: "assigned_agent_id"}]}
    {type: "btree", field: [{name: "assigned_queue"}]}
    {type: "btree", field: [{name: "status"}]}
    {type: "btree", field: [{name: "priority"}]}
    {type: "btree", field: [{name: "opened_at", op: "desc"}]}
  ]
  guid = "BO4cEAupXXtHV7Dv5KRe2_WAtQM"
}
