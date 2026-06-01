query "claims/{claim_id}" verb=PATCH {
  api_group = "claims"
  description = "Update a claim's status, assignment, priority, or amount approved. Each change is logged to the timeline."
  auth = "user"
  input {
    int claim_id { table = "claim" }
    text status? filters=trim|lower
    text priority? filters=trim|lower
    int assigned_agent_id? { table = "user" }
    text assigned_queue? filters=trim|lower
    decimal amount_approved? filters=min:0
    text note? filters=trim
  }
  stack {
    db.get "claim" {
      field_name = "id"
      field_value = $input.claim_id
    } as $existing

    precondition ($existing != null) {
      error_type = "notfound"
      error = "Claim not found"
    }

    var $updates { value = {} }

    conditional {
      if ($input.status != null && $input.status != $existing.status) {
        var.update $updates { value = $updates|set:"status":$input.status }
        function.run "log_claim_event" {
          input = {
            claim_id: $input.claim_id,
            actor_id: $auth.id,
            event_type: "status_changed",
            message: ("Status: " ~ $existing.status ~ " → " ~ $input.status),
            payload: { from: $existing.status, to: $input.status }
          }
        }
        conditional {
          if ($input.status == "closed" || $input.status == "paid" || $input.status == "denied") {
            var.update $updates { value = $updates|set:"closed_at":now }
            function.run "log_claim_event" {
              input = {
                claim_id: $input.claim_id,
                actor_id: $auth.id,
                event_type: "closed",
                message: ("Claim closed with status: " ~ $input.status)
              }
            }
          }
        }
      }
    }

    conditional {
      if ($input.priority != null && $input.priority != $existing.priority) {
        var.update $updates { value = $updates|set:"priority":$input.priority }
      }
    }

    conditional {
      if ($input.assigned_agent_id != null && $input.assigned_agent_id != $existing.assigned_agent_id) {
        var.update $updates { value = $updates|set:"assigned_agent_id":$input.assigned_agent_id }
        function.run "log_claim_event" {
          input = {
            claim_id: $input.claim_id,
            actor_id: $auth.id,
            event_type: "assigned",
            message: "Reassigned to agent",
            payload: { from: $existing.assigned_agent_id, to: $input.assigned_agent_id }
          }
        }
      }
    }

    conditional {
      if ($input.assigned_queue != null && $input.assigned_queue != $existing.assigned_queue) {
        var.update $updates { value = $updates|set:"assigned_queue":$input.assigned_queue }
        function.run "log_claim_event" {
          input = {
            claim_id: $input.claim_id,
            actor_id: $auth.id,
            event_type: "assigned",
            message: ("Assigned to queue: " ~ $input.assigned_queue),
            payload: { from: $existing.assigned_queue, to: $input.assigned_queue }
          }
        }
      }
    }

    conditional {
      if ($input.amount_approved != null && $input.amount_approved != $existing.amount_approved) {
        var.update $updates { value = $updates|set:"amount_approved":$input.amount_approved }
        function.run "log_claim_event" {
          input = {
            claim_id: $input.claim_id,
            actor_id: $auth.id,
            event_type: "amount_updated",
            message: "Approved amount updated",
            payload: { from: $existing.amount_approved, to: $input.amount_approved }
          }
        }
      }
    }

    conditional {
      if ($input.note != null && $input.note != "") {
        function.run "log_claim_event" {
          input = {
            claim_id: $input.claim_id,
            actor_id: $auth.id,
            event_type: "note_added",
            message: $input.note
          }
        }
      }
    }

    precondition ((($updates|is_empty) == false) || ($input.note != null && $input.note != "")) {
      error_type = "inputerror"
      error = "No changes provided"
    }

    conditional {
      if (($updates|is_empty) == false) {
        db.patch "claim" {
          field_name = "id"
          field_value = $input.claim_id
          data = $updates
        } as $updated
      }
      else {
        var $updated { value = $existing }
      }
    }

    conditional {
      if ($input.status != null && $input.status != $existing.status) {
        db.get "customer" {
          field_name = "id"
          field_value = $existing.customer_id
        } as $customer

        function.run "record_customer_event" {
          input = {
            customer_id: $existing.customer_id,
            event_type: ("claim_" ~ $input.status),
            payload: {
              claim_id: $existing.id,
              claim_number: $existing.claim_number,
              from: $existing.status,
              to: $input.status,
              amount: ($updated.amount_approved ?? $existing.amount_approved ?? $existing.amount_requested)
            }
          }
        }

        conditional {
          if ($customer != null) {
            function.run "notify_customer" {
              input = {
                customer_id: $existing.customer_id,
                recipient: $customer.email,
                template_name: ("claim_" ~ $input.status),
                channel: "email",
                vars: {
                  claim_number: $existing.claim_number,
                  customer_name: $customer.first_name,
                  status: $input.status,
                  amount: (($updated.amount_approved ?? $existing.amount_approved ?? $existing.amount_requested)|to_text)
                }
              }
            }
          }
        }

        conditional {
          if ($input.status == "approved") {
            var $payout_amount { value = $updated.amount_approved ?? $existing.amount_approved ?? $existing.amount_requested }
            function.run "create_payout_invoice" {
              input = {
                customer_id: $existing.customer_id,
                claim_ref: $existing.claim_number,
                amount: $payout_amount,
                description: ("Payout for claim " ~ $existing.claim_number)
              }
            } as $invoice_result

            conditional {
              if ($invoice_result != null) {
                function.run "log_claim_event" {
                  input = {
                    claim_id: $existing.id,
                    actor_id: $auth.id,
                    event_type: "amount_updated",
                    message: "Payout invoice created in Billing & Payments",
                    payload: $invoice_result
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  response = $updated
  guid = "Ycza9iYDtjrSDEDoYzXJKWDlwFc"
}
