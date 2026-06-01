query "claims" verb=GET {
  api_group = "claims"
  description = "List claims with optional filters"
  auth = "user"
  input {
    text status? filters=trim|lower
    text priority? filters=trim|lower
    text claim_type? filters=trim|lower
    int assigned_agent_id?
    int customer_id?
    int page?=1 filters=min:1
    int per_page?=25 filters=min:1|max:100
  }
  stack {
    db.query "claim" {
      where = $db.claim.status ==? $input.status && $db.claim.priority ==? $input.priority && $db.claim.claim_type ==? $input.claim_type && $db.claim.assigned_agent_id ==? $input.assigned_agent_id && $db.claim.customer_id ==? $input.customer_id
      sort = { opened_at: "desc" }
      return = {
        type: "list",
        paging: { page: $input.page, per_page: $input.per_page, totals: true }
      }
    } as $claims
  }
  response = $claims
  guid = "GSlSu5FeLJ8sYpNDMM2AerWYDOw"
}
