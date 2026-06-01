query "claims/{claim_id}" verb=GET {
  api_group = "claims"
  description = "Fetch a single claim with its customer and assigned agent"
  auth = "user"
  input {
    int claim_id { table = "claim" }
  }
  stack {
    db.get "claim" {
      field_name = "id"
      field_value = $input.claim_id
    } as $claim

    precondition ($claim != null) {
      error_type = "notfound"
      error = "Claim not found"
    }

    var $customer { value = null }
    conditional {
      if ($claim.customer_id != null && $claim.customer_id > 0) {
        db.get "customer" {
          field_name = "id"
          field_value = $claim.customer_id
        } as $customer_record
        var.update $customer { value = $customer_record }
      }
    }

    var $assigned_agent { value = null }
    conditional {
      if ($claim.assigned_agent_id != null && $claim.assigned_agent_id > 0) {
        db.get "user" {
          field_name = "id"
          field_value = $claim.assigned_agent_id
        } as $agent_record
        var.update $assigned_agent { value = $agent_record }
      }
    }

    var $customer_name { value = null }
    var $customer_email { value = null }
    var $customer_policy_number { value = null }
    conditional {
      if ($customer != null) {
        var.update $customer_name { value = ($customer.first_name ~ " " ~ $customer.last_name) }
        var.update $customer_email { value = $customer.email }
        var.update $customer_policy_number { value = $customer.policy_number }
      }
    }

    var $assigned_agent_name { value = null }
    var $assigned_agent_email { value = null }
    conditional {
      if ($assigned_agent != null) {
        var.update $assigned_agent_name { value = $assigned_agent.name }
        var.update $assigned_agent_email { value = $assigned_agent.email }
      }
    }
  }
  response = {
    id: $claim.id,
    created_at: $claim.created_at,
    claim_number: $claim.claim_number,
    customer_id: $claim.customer_id,
    assigned_agent_id: $claim.assigned_agent_id,
    assigned_queue: $claim.assigned_queue,
    claim_type: $claim.claim_type,
    status: $claim.status,
    priority: $claim.priority,
    amount_requested: $claim.amount_requested,
    amount_approved: $claim.amount_approved,
    summary: $claim.summary,
    opened_at: $claim.opened_at,
    closed_at: $claim.closed_at,
    sla_due_at: $claim.sla_due_at,
    customer_name: $customer_name,
    customer_email: $customer_email,
    customer_policy_number: $customer_policy_number,
    assigned_agent_name: $assigned_agent_name,
    assigned_agent_email: $assigned_agent_email
  }
  guid = "xgr1VvV-kaqvaCW1CrrvEProxN4"
}
