query "claims" verb=POST {
  api_group = "claims"
  description = "Open a new claim and seed its timeline"
  auth = "user"
  input {
    int customer_id { table = "customer" }
    enum claim_type {
      values = ["auto", "property", "health", "liability", "travel", "other"]
    }
    decimal amount_requested filters=min:0
    text summary filters=trim
    enum priority?="medium" {
      values = ["low", "medium", "high", "urgent"]
    }
    int assigned_agent_id? { table = "user" }
  }
  stack {
    db.get "customer" {
      field_name = "id"
      field_value = $input.customer_id
    } as $customer

    precondition ($customer != null) {
      error_type = "notfound"
      error = "Customer not found"
    }

    function.run "generate_claim_number" {
      input = {}
    } as $claim_number

    var $sla_hours { value = 72 }
    conditional {
      if ($input.priority == "urgent") {
        var.update $sla_hours { value = 4 }
      }
      elseif ($input.priority == "high") {
        var.update $sla_hours { value = 24 }
      }
      elseif ($input.priority == "low") {
        var.update $sla_hours { value = 168 }
      }
    }

    var $sla_due_at { value = now|transform_timestamp:("+" ~ ($sla_hours|to_text) ~ " hours") }

    db.add "claim" {
      data = {
        claim_number: $claim_number,
        customer_id: $input.customer_id,
        assigned_agent_id: $input.assigned_agent_id,
        claim_type: $input.claim_type,
        status: "new",
        priority: $input.priority,
        amount_requested: $input.amount_requested,
        summary: $input.summary,
        opened_at: now,
        sla_due_at: $sla_due_at
      }
    } as $claim

    function.run "log_claim_event" {
      input = {
        claim_id: $claim.id,
        actor_id: $auth.id,
        event_type: "created",
        message: "Claim opened",
        payload: { claim_number: $claim_number, priority: $input.priority }
      }
    }

    conditional {
      if ($input.assigned_agent_id != null) {
        function.run "log_claim_event" {
          input = {
            claim_id: $claim.id,
            actor_id: $auth.id,
            event_type: "assigned",
            message: "Assigned to agent",
            payload: { assigned_agent_id: $input.assigned_agent_id }
          }
        }
      }
    }

    function.run "record_customer_event" {
      input = {
        customer_id: $input.customer_id,
        event_type: "claim_opened",
        payload: {
          claim_id: $claim.id,
          claim_number: $claim_number,
          claim_type: $input.claim_type,
          priority: $input.priority,
          amount_requested: $input.amount_requested
        }
      }
    }

    function.run "notify_customer" {
      input = {
        customer_id: $input.customer_id,
        recipient: $customer.email,
        template_name: "claim_opened",
        channel: "email",
        vars: {
          claim_number: $claim_number,
          customer_name: $customer.first_name,
          amount: ($input.amount_requested|to_text)
        }
      }
    }
  }
  response = $claim
  guid = "bDSZVQU4tfBjE6tdZlJKsKi4CXY"
}
